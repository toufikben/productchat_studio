package com.productchat.aiphotostudio.native

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.FloatBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs

/** Android bridge for local image operations and optional LaMa ONNX inference. */
class SeikaChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "SeikaChannel"
        private const val LAMA_SIZE = 512
        private const val MAX_ESRGAN_DIM = 1024
        private const val MAX_IMAGE_DIM = 4096
        private const val MAX_OUTPUT_PIXELS = MAX_IMAGE_DIM * MAX_IMAGE_DIM
        private const val INFERENCE_TIMEOUT_SECONDS = 180L
    }

    private val environment = OrtEnvironment.getEnvironment()
    private val lock = Any()
    private val workQueue: ExecutorService = Executors.newSingleThreadExecutor()
    private val timeoutScheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private var lamaSession: OrtSession? = null
    private var esrganSession: OrtSession? = null
    private var activeInference: InferenceControl? = null
    private val patchMatch = PatchMatchRemover()

    fun attach(channel: MethodChannel) = channel.setMethodCallHandler(this)

    fun close() {
        cancelActiveInference("bridge closed")
        workQueue.shutdownNow()
        try { workQueue.awaitTermination(5, TimeUnit.SECONDS) } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
        timeoutScheduler.shutdownNow()
        unloadModels()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "cancelInference") {
            cancelActiveInference("cancelled by user")
            result.success(true)
            return
        }
        workQueue.execute {
            try {
                when (call.method) {
                "removeBackground" -> {
                    val path = required(call, "imagePath")
                    val quality = call.argument<String>("quality") ?: "fast"
                    result.success(removeBackground(path, quality).absolutePath)
                }
                "inpaint" -> {
                    val image = required(call, "imagePath")
                    val mask = required(call, "maskPath")
                    val model = call.argument<String>("modelPath")
                    result.success(inpaint(image, mask, model).absolutePath)
                }
                "upscale" -> {
                    val path = required(call, "imagePath")
                    val factor = call.argument<Int>("factor") ?: 2
                    result.success(upscale(path, factor, call.argument<String>("modelPath")).absolutePath)
                }
                "addShadow" -> result.success(addShadow(required(call, "imagePath")).absolutePath)
                "export" -> result.success(export(required(call, "imagePath"), call.argument<String>("format") ?: "jpg").absolutePath)
                "loadModel" -> {
                    loadModel(required(call, "modelPath"), call.argument<String>("modelType") ?: "lama")
                    result.success(true)
                }
                "unloadModel" -> {
                    unloadModels()
                    result.success(true)
                }
                "isLoaded" -> result.success(lamaSession != null || esrganSession != null)
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                Log.e(TAG, "${call.method} failed", e)
                result.error("SEIKA_ERROR", e.message ?: "Image operation failed", null)
            }
        }
    }

    private fun removeBackground(path: String, quality: String): File {
        val source = decodeBitmap(path) ?: error("Cannot decode image: $path")
        return try {
            val output = if (quality != "fast") {
                val control = beginInference()
                try {
                    runLaMa(source, null, control) ?: patchMatch.remove(source)
                } finally {
                    endInference(control)
                }
            } else patchMatch.remove(source)
            save(output, "remove_bg", "png")
        } finally {
            if (!source.isRecycled) source.recycle()
        }
    }

    private fun inpaint(imagePath: String, maskPath: String, modelPath: String?): File {
        val image = decodeBitmap(imagePath) ?: error("Cannot decode image: $imagePath")
        val mask = decodeBitmap(maskPath) ?: error("Cannot decode mask: $maskPath")
        return try {
            require(image.width == mask.width && image.height == mask.height) { "Image and mask dimensions must match" }
            if (modelPath != null) ensureModel(modelPath, "lama")
            val control = beginInference()
            val output = try {
                runLaMa(image, mask, control)
                    ?: error("LaMa model is not loaded")
            } finally {
                endInference(control)
            }
            save(output, "inpaint", "png")
        } finally {
            if (!image.isRecycled) image.recycle()
            if (!mask.isRecycled) mask.recycle()
        }
    }

    private fun beginInference(): InferenceControl {
        val control = InferenceControl()
        synchronized(lock) {
            activeInference?.cancel("superseded by a newer inference")
            activeInference = control
        }
        control.timeout = timeoutScheduler.schedule({
            control.cancel("native inference timeout")
        }, INFERENCE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        return control
    }

    private fun endInference(control: InferenceControl) {
        control.timeout?.cancel(false)
        synchronized(lock) {
            if (activeInference === control) activeInference = null
        }
    }

    private fun cancelActiveInference(reason: String) {
        synchronized(lock) { activeInference?.cancel(reason) }
    }

    private fun checkCancelled(control: InferenceControl) {
        if (control.cancelled.get()) throw InferenceCancelledException(control.reason)
    }

    private fun upscale(path: String, factor: Int, modelPath: String?): File {
        require(factor == 2 || factor == 4) { "Upscale factor must be 2 or 4" }
        val source = decodeBitmap(path) ?: error("Cannot decode image: $path")
        return try {
            require(source.width.toLong() * factor <= MAX_IMAGE_DIM &&
                source.height.toLong() * factor <= MAX_IMAGE_DIM) {
                "Upscale output exceeds the configured image limit"
            }
            if (modelPath != null) ensureModel(modelPath, "esrgan")
            val output = synchronized(lock) { runEsrgan(source) }
                ?: Bitmap.createScaledBitmap(source, source.width * factor, source.height * factor, true)
            save(output, "upscale_${factor}x", "png")
        } finally {
            if (!source.isRecycled) source.recycle()
        }
    }

    private fun loadModel(path: String, type: String) {
        require(type == "lama" || type == "esrgan") { "modelType must be lama or esrgan" }
        val options = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceAtMost(4))
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            try { addNnapi() } catch (t: Throwable) { Log.w(TAG, "NNAPI unavailable; using CPU", t) }
        }
        try {
            val newSession = environment.createSession(path, options)
            synchronized(lock) {
                if (type == "lama") {
                    val old = lamaSession
                    lamaSession = newSession
                    old?.close()
                } else {
                    val old = esrganSession
                    esrganSession = newSession
                    old?.close()
                }
            }
        } finally {
            options.close()
        }
    }

    private fun ensureModel(path: String, type: String) {
        synchronized(lock) {
            if (if (type == "lama") lamaSession != null else esrganSession != null) return
        }
        loadModel(path, type)
    }

    private fun unloadModels() = synchronized(lock) {
        lamaSession?.close(); lamaSession = null
        esrganSession?.close(); esrganSession = null
    }

    private fun runLaMa(image: Bitmap, mask: Bitmap?, control: InferenceControl): Bitmap? {
        val session = lamaSession ?: return null
        var imageTensor: OnnxTensor? = null
        var maskTensor: OnnxTensor? = null
        var output: OrtSession.Result? = null
        var resized: Bitmap? = null
        var maskBitmap: Bitmap? = null
        var runOptions: OrtSession.RunOptions? = null
        try {
            checkCancelled(control)
            resized = safeResize(image, LAMA_SIZE, LAMA_SIZE)
            maskBitmap = mask?.let { safeResize(it, LAMA_SIZE, LAMA_SIZE) }
                ?: solidBitmap(LAMA_SIZE, LAMA_SIZE, Color.WHITE)
            val preparedImage = resized!!
            val preparedMask = maskBitmap!!
            val plane = LAMA_SIZE * LAMA_SIZE
            val imagePixels = IntArray(plane)
            val maskPixels = IntArray(plane)
            preparedImage.getPixels(imagePixels, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)
            preparedMask.getPixels(maskPixels, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)
            val imageArray = FloatArray(plane * 3)
            val maskArray = FloatArray(plane)
            for (i in 0 until plane) {
                if ((i and 0x3fff) == 0) checkCancelled(control)
                val p = imagePixels[i]
                imageArray[i] = Color.red(p) / 255f
                imageArray[plane + i] = Color.green(p) / 255f
                imageArray[plane * 2 + i] = Color.blue(p) / 255f
                val m = maskPixels[i]
                maskArray[i] = if (((Color.red(m) + Color.green(m) + Color.blue(m)) / 3) > 128) 1f else 0f
            }
            imageTensor = OnnxTensor.createTensor(environment, FloatBuffer.wrap(imageArray), longArrayOf(1, 3, 512, 512))
            maskTensor = OnnxTensor.createTensor(environment, FloatBuffer.wrap(maskArray), longArrayOf(1, 1, 512, 512))
            checkCancelled(control)
            val names = session.inputNames.toList()
            require(names.isNotEmpty()) { "LaMa session has no inputs" }
            val imageName = names.firstOrNull { it.equals("image", ignoreCase = true) }
                ?: names.firstOrNull { it.contains("image", ignoreCase = true) }
                ?: names.first()
            val maskName = names.firstOrNull { it.equals("mask", ignoreCase = true) }
                ?: names.firstOrNull { it.contains("mask", ignoreCase = true) }
            val inputs = mutableMapOf<String, OnnxTensor>(imageName to imageTensor!!)
            if (maskName != null && maskName != imageName) inputs[maskName] = maskTensor!!
            runOptions = OrtSession.RunOptions()
            control.runOptions = runOptions
            checkCancelled(control)
            output = session.run(inputs, runOptions)
            checkCancelled(control)
            val tensor = output[0] as OnnxTensor
            val shape = tensor.info.shape
            require(shape.size >= 4) { "LaMa output must be rank 4" }
            val channels = shape[1].toInt()
            val width = shape[3].toInt()
            val height = shape[2].toInt()
            require(channels >= 3 && width > 0 && height > 0) {
                "LaMa output has invalid shape: ${shape.contentToString()}"
            }
            require(width.toLong() * height.toLong() <= MAX_OUTPUT_PIXELS) {
                "LaMa output exceeds the configured pixel limit"
            }
            val count = channels * width * height
            val values = FloatArray(count)
            tensor.floatBuffer.rewind(); tensor.floatBuffer.get(values)
            val resultPixels = IntArray(width * height)
            for (i in resultPixels.indices) {
                fun channel(c: Int): Int = (values[c * width * height + i] * 255f).toInt().coerceIn(0, 255)
                val alpha = if (channels > 3) channel(3) else 255
                resultPixels[i] = (alpha shl 24) or (channel(0) shl 16) or (channel(1) shl 8) or channel(2)
            }
            val outputBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
                setPixels(resultPixels, 0, width, 0, 0, width, height)
            }
            val restored = if (width == image.width && height == image.height) {
                outputBitmap
            } else {
                Bitmap.createScaledBitmap(outputBitmap, image.width, image.height, true).also {
                    if (!outputBitmap.isRecycled) outputBitmap.recycle()
                }
            }
            return restored
        } catch (e: InferenceCancelledException) {
            throw e
        } catch (e: Throwable) {
            Log.e(TAG, "LaMa inference failed", e); return null
        } finally {
            control.runOptions = null
            try { runOptions?.close() } catch (_: Throwable) {}
            try { output?.close() } catch (_: Throwable) {}
            try { maskTensor?.close() } catch (_: Throwable) {}
            try { imageTensor?.close() } catch (_: Throwable) {}
            if (resized != null && resized !== image && !resized!!.isRecycled) resized!!.recycle()
            if (maskBitmap != null && maskBitmap !== mask && !maskBitmap!!.isRecycled) maskBitmap!!.recycle()
        }
    }

    private class InferenceControl {
        val cancelled = AtomicBoolean(false)
        @Volatile var reason: String = "cancelled"
        @Volatile var runOptions: OrtSession.RunOptions? = null
        @Volatile var timeout: ScheduledFuture<*>? = null

        fun cancel(message: String) {
            reason = message
            cancelled.set(true)
            try { runOptions?.setTerminate(true) } catch (_: Throwable) {}
        }
    }

    private class InferenceCancelledException(message: String) : RuntimeException(message)

    private fun runEsrgan(image: Bitmap): Bitmap? {
        val session = esrganSession ?: return null
        // The currently uploaded Real-ESRGAN artifact is .pth, not ONNX. Keep
        // this path dormant until an ONNX export is supplied.
        if (session.inputNames.isEmpty()) return null
        return null
    }

    private fun floodRemove(source: Bitmap): Bitmap {
        val output = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
        try {
            val corner = source.getPixel(0, 0)
            for (y in 0 until source.height) for (x in 0 until source.width) {
                val pixel = source.getPixel(x, y)
                output.setPixel(x, y, if (colorDistance(pixel, corner) < 52) Color.TRANSPARENT else pixel)
            }
            return output
        } catch (error: Throwable) {
            if (!output.isRecycled) output.recycle()
            throw error
        }
    }

    private fun addShadow(path: String): File {
        val source = decodeBitmap(path) ?: error("Cannot decode image")
        return try {
            val output = source.copy(Bitmap.Config.ARGB_8888, true)
            Canvas(output).drawOval(source.width * .18f, source.height * .72f, source.width * .82f, source.height * .88f,
                Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(72, 0, 0, 0) })
            save(output, "shadow", "png")
        } finally {
            if (!source.isRecycled) source.recycle()
        }
    }

    private fun export(path: String, format: String): File {
        val source = decodeBitmap(path) ?: error("Cannot decode image")
        return try {
            save(source, "export", format)
        } finally {
            if (!source.isRecycled) source.recycle()
        }
    }

    private fun decodeBitmap(path: String): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outWidth / sample > MAX_IMAGE_DIM || bounds.outHeight / sample > MAX_IMAGE_DIM) {
            sample *= 2
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = BitmapFactory.decodeFile(path, options) ?: return null
        if (decoded.width <= MAX_IMAGE_DIM && decoded.height <= MAX_IMAGE_DIM) return decoded
        val scale = minOf(
            MAX_IMAGE_DIM.toFloat() / decoded.width,
            MAX_IMAGE_DIM.toFloat() / decoded.height,
        )
        return try {
            Bitmap.createScaledBitmap(
                decoded,
                (decoded.width * scale).toInt().coerceAtLeast(1),
                (decoded.height * scale).toInt().coerceAtLeast(1),
                true,
            )
        } finally {
            if (!decoded.isRecycled) decoded.recycle()
        }
    }
    private fun safeResize(src: Bitmap, width: Int, height: Int): Bitmap = try {
        if (src.width == width && src.height == height) src else Bitmap.createScaledBitmap(src, width, height, true)
    } catch (_: Throwable) {
        Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { Canvas(it).drawBitmap(src, null, Rect(0, 0, width, height), Paint(Paint.ANTI_ALIAS_FLAG)) }
    }
    private fun solidBitmap(width: Int, height: Int, color: Int) = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply { eraseColor(color) }
    private fun colorDistance(a: Int, b: Int) = abs(Color.red(a) - Color.red(b)) + abs(Color.green(a) - Color.green(b)) + abs(Color.blue(a) - Color.blue(b))
    private fun required(call: MethodCall, key: String) = call.argument<String>(key) ?: error("Missing $key")
    private fun save(bitmap: Bitmap, prefix: String, format: String): File {
        val extension = if (format.lowercase() == "png") "png" else "jpg"
        val file = File(context.cacheDir, "${prefix}_${System.currentTimeMillis()}.$extension")
        try {
            FileOutputStream(file).use { stream ->
                require(bitmap.compress(
                    if (extension == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG,
                    92,
                    stream,
                )) { "Failed to encode image output" }
            }
            return file
        } finally {
            if (!bitmap.isRecycled) bitmap.recycle()
        }
    }
}
