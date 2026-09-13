package com.productchat.studio.native

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
import kotlin.math.abs

/** Android bridge for local image operations and optional LaMa ONNX inference. */
class SeikaChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "SeikaChannel"
        private const val LAMA_SIZE = 512
        private const val MAX_ESRGAN_DIM = 1024
    }

    private val environment = OrtEnvironment.getEnvironment()
    private val lock = Any()
    private var lamaSession: OrtSession? = null
    private var esrganSession: OrtSession? = null

    fun attach(channel: MethodChannel) = channel.setMethodCallHandler(this)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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

    private fun removeBackground(path: String, quality: String): File {
        val source = decodeBitmap(path) ?: error("Cannot decode image: $path")
        val output = if (quality != "fast") {
            synchronized(lock) { runLaMa(source, null) } ?: floodRemove(source)
        } else floodRemove(source)
        return save(output, "remove_bg", "png")
    }

    private fun inpaint(imagePath: String, maskPath: String, modelPath: String?): File {
        val image = decodeBitmap(imagePath) ?: error("Cannot decode image: $imagePath")
        val mask = decodeBitmap(maskPath) ?: error("Cannot decode mask: $maskPath")
        require(image.width == mask.width && image.height == mask.height) { "Image and mask dimensions must match" }
        if (modelPath != null) ensureModel(modelPath, "lama")
        val output = synchronized(lock) { runLaMa(image, mask) }
            ?: error("LaMa model is not loaded")
        return save(output, "inpaint", "png")
    }

    private fun upscale(path: String, factor: Int, modelPath: String?): File {
        require(factor == 2 || factor == 4) { "Upscale factor must be 2 or 4" }
        val source = decodeBitmap(path) ?: error("Cannot decode image: $path")
        if (modelPath != null) ensureModel(modelPath, "esrgan")
        val output = synchronized(lock) { runEsrgan(source) }
            ?: Bitmap.createScaledBitmap(source, source.width * factor, source.height * factor, true)
        return save(output, "upscale_${factor}x", "png")
    }

    private fun loadModel(path: String, type: String) {
        require(type == "lama" || type == "esrgan") { "modelType must be lama or esrgan" }
        val options = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceAtMost(4))
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            try { addNnapi() } catch (t: Throwable) { Log.w(TAG, "NNAPI unavailable; using CPU", t) }
        }
        synchronized(lock) {
            if (type == "lama") {
                lamaSession?.close()
                lamaSession = environment.createSession(path, options)
            } else {
                esrganSession?.close()
                esrganSession = environment.createSession(path, options)
            }
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

    private fun runLaMa(image: Bitmap, mask: Bitmap?): Bitmap? {
        val session = lamaSession ?: return null
        var imageTensor: OnnxTensor? = null
        var maskTensor: OnnxTensor? = null
        var output: OrtSession.Result? = null
        try {
            val resized = safeResize(image, LAMA_SIZE, LAMA_SIZE)
            val maskBitmap = mask?.let { safeResize(it, LAMA_SIZE, LAMA_SIZE) }
                ?: solidBitmap(LAMA_SIZE, LAMA_SIZE, Color.WHITE)
            val plane = LAMA_SIZE * LAMA_SIZE
            val imagePixels = IntArray(plane)
            val maskPixels = IntArray(plane)
            resized.getPixels(imagePixels, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)
            maskBitmap.getPixels(maskPixels, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)
            val imageArray = FloatArray(plane * 3)
            val maskArray = FloatArray(plane)
            for (i in 0 until plane) {
                val p = imagePixels[i]
                imageArray[i] = Color.red(p) / 255f
                imageArray[plane + i] = Color.green(p) / 255f
                imageArray[plane * 2 + i] = Color.blue(p) / 255f
                val m = maskPixels[i]
                maskArray[i] = if (((Color.red(m) + Color.green(m) + Color.blue(m)) / 3) > 128) 1f else 0f
            }
            imageTensor = OnnxTensor.createTensor(environment, FloatBuffer.wrap(imageArray), longArrayOf(1, 3, 512, 512))
            maskTensor = OnnxTensor.createTensor(environment, FloatBuffer.wrap(maskArray), longArrayOf(1, 1, 512, 512))
            val names = session.inputNames.toList()
            val inputs = mutableMapOf<String, OnnxTensor>(names[0] to imageTensor!!)
            if (names.size > 1) inputs[names[1]] = maskTensor!!
            output = session.run(inputs)
            val tensor = output[0] as OnnxTensor
            val shape = tensor.info.shape
            val channels = shape[1].toInt()
            val width = shape[3].toInt()
            val height = shape[2].toInt()
            val count = channels * width * height
            val values = FloatArray(count)
            tensor.floatBuffer.rewind(); tensor.floatBuffer.get(values)
            val resultPixels = IntArray(width * height)
            for (i in resultPixels.indices) {
                fun channel(c: Int): Int = (values[c * width * height + i] * 255f).toInt().coerceIn(0, 255)
                val alpha = if (channels > 3) channel(3) else 255
                resultPixels[i] = (alpha shl 24) or (channel(0) shl 16) or (channel(1) shl 8) or channel(2)
            }
            return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
                setPixels(resultPixels, 0, width, 0, 0, width, height)
            }.let { Bitmap.createScaledBitmap(it, image.width, image.height, true) }
        } catch (e: Throwable) {
            Log.e(TAG, "LaMa inference failed", e); return null
        } finally {
            try { output?.close() } catch (_: Throwable) {}
            try { maskTensor?.close() } catch (_: Throwable) {}
            try { imageTensor?.close() } catch (_: Throwable) {}
        }
    }

    private fun runEsrgan(image: Bitmap): Bitmap? {
        val session = esrganSession ?: return null
        // The currently uploaded Real-ESRGAN artifact is .pth, not ONNX. Keep
        // this path dormant until an ONNX export is supplied.
        if (session.inputNames.isEmpty()) return null
        return null
    }

    private fun floodRemove(source: Bitmap): Bitmap {
        val output = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
        val corner = source.getPixel(0, 0)
        for (y in 0 until source.height) for (x in 0 until source.width) {
            val pixel = source.getPixel(x, y)
            output.setPixel(x, y, if (colorDistance(pixel, corner) < 52) Color.TRANSPARENT else pixel)
        }
        return output
    }

    private fun addShadow(path: String): File {
        val source = decodeBitmap(path) ?: error("Cannot decode image")
        val output = source.copy(Bitmap.Config.ARGB_8888, true)
        Canvas(output).drawOval(source.width * .18f, source.height * .72f, source.width * .82f, source.height * .88f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(72, 0, 0, 0) })
        return save(output, "shadow", "png")
    }

    private fun export(path: String, format: String): File = save(decodeBitmap(path) ?: error("Cannot decode image"), "export", format)

    private fun decodeBitmap(path: String): Bitmap? = BitmapFactory.decodeFile(path)
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
        FileOutputStream(file).use { bitmap.compress(if (extension == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG, 92, it) }
        if (!bitmap.isRecycled) bitmap.recycle()
        return file
    }
}
