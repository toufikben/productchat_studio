package com.productchat.studio.native

import ai.onnxruntime.*
import com.productchat.aiphotostudio.native.PatchMatchRemover
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.nio.FloatBuffer
import kotlin.math.max
import kotlin.math.min

/**
 * SeikaChannel — Native bridge for on-device AI (LaMa + Real-ESRGAN).
 */
class SeikaChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/seika"
        private const val LAMA_SIZE = 512
        private const val ESRGAN_MAX_DIM = 1024
        private const val TAG = "SeikaChannel"
    }

    private var lamaSession: OrtSession? = null
    private var esrganSession: OrtSession? = null
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "removeBg"    -> handleRemoveBg(call, result)
            "inpaint"     -> handleInpaint(call, result)
            "upscale"     -> handleUpscale(call, result)
            "loadModel"   -> handleLoadModel(call, result)
            "unloadModel" -> handleUnload(result)
            "isLoaded"    -> synchronized(lock) {
                result.success(lamaSession != null || esrganSession != null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleRemoveBg(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val quality = call.argument<String>("quality") ?: "fast"
        if (path == null) {
            result.error("INVALID_ARGS", "path is null", null); return
        }
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_nobg.png")

        try {
            val bmp = decodeBitmap(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode image", null)

            val output: Bitmap = when (quality) {
                "balanced", "best" -> {
                    synchronized(lock) {
                        if (lamaSession != null) runLaMa(bmp, null)
                        else PatchMatchRemover().remove(bmp)
                    } ?: PatchMatchRemover().remove(bmp)
                }
                else -> PatchMatchRemover().remove(bmp)
            }

            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf(
                "ok" to true,
                "outputPath" to outputPath,
                "width" to output.width,
                "height" to output.height,
                "quality" to quality
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "removeBg failed", e)
            result.error("PROCESSING_ERROR", e.message, null)
        }
    }

    private fun handleInpaint(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val maskPath = call.argument<String>("maskPath")
        if (path == null || maskPath == null) {
            result.error("INVALID_ARGS", "path and maskPath required", null); return
        }
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_inpaint.png")

        try {
            val img = decodeBitmap(path)
            val mask = decodeBitmap(maskPath)
            if (img == null || mask == null) {
                return result.error("DECODE_FAIL", "Cannot decode", null)
            }

            val output = synchronized(lock) { runLaMa(img, mask) } ?: img
            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf("ok" to true, "outputPath" to outputPath))
        } catch (e: Throwable) {
            Log.e(TAG, "inpaint failed", e)
            result.error("INPAINT_ERROR", e.message, null)
        }
    }

    private fun handleUpscale(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val factor = call.argument<Int>("factor") ?: 2
        if (path == null) {
            result.error("INVALID_ARGS", "path required", null); return
        }
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_${factor}x.png")

        try {
            val bmp = decodeBitmap(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode", null)

            val output = synchronized(lock) { runEsrgan(bmp, factor) } ?: bmp
            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf(
                "ok" to true,
                "outputPath" to outputPath,
                "width" to output.width,
                "height" to output.height,
                "factor" to factor
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "upscale failed", e)
            result.error("UPSCALE_ERROR", e.message, null)
        }
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelType = call.argument<String>("modelType")
        val modelPath = call.argument<String>("modelPath")
        if (modelPath == null) {
            result.error("NO_MODEL", "modelPath is required", null); return
        }

        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(Runtime.getRuntime().availableProcessors().coerceAtMost(4))
                setInterOpNumThreads(1)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                try {
                    addConfigEntry("session.intra_op.allow_spinning", "0")
                } catch (_: Throwable) {}
                try { addNnapi() } catch (t: Throwable) {
                    Log.w(TAG, "NNAPI unavailable, using CPU")
                }
            }

            synchronized(lock) {
                when (modelType) {
                    "lama" -> {
                        lamaSession?.close()
                        lamaSession = env.createSession(modelPath, opts)
                    }
                    "esrgan" -> {
                        esrganSession?.close()
                        esrganSession = env.createSession(modelPath, opts)
                    }
                    else -> {
                        result.error("UNKNOWN_MODEL", "modelType must be lama|esrgan", null)
                        return
                    }
                }
            }
            result.success(mapOf("ok" to true, "modelType" to modelType))
        } catch (e: Throwable) {
            Log.e(TAG, "loadModel failed", e)
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun handleUnload(result: MethodChannel.Result) {
        try {
            synchronized(lock) {
                lamaSession?.close(); lamaSession = null
                esrganSession?.close(); esrganSession = null
            }
            result.success(true)
        } catch (e: Throwable) {
            result.error("UNLOAD_ERROR", e.message, null)
        }
    }

    private fun runLaMa(image: Bitmap, mask: Bitmap?): Bitmap? {
        val session = lamaSession ?: return null

        var imgTensor: OnnxTensor? = null
        var maskTensor: OnnxTensor? = null
        var output: OrtSession.Result? = null

        try {
            val imgResized = safeResize(image, LAMA_SIZE, LAMA_SIZE)
            val maskResized = mask?.let { safeResize(it, LAMA_SIZE, LAMA_SIZE) }
                ?: solidBitmap(LAMA_SIZE, LAMA_SIZE, Color.WHITE)

            val imgPx = IntArray(LAMA_SIZE * LAMA_SIZE)
            imgResized.getPixels(imgPx, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)

            val maskPx = IntArray(LAMA_SIZE * LAMA_SIZE)
            maskResized.getPixels(maskPx, 0, LAMA_SIZE, 0, 0, LAMA_SIZE, LAMA_SIZE)

            val plane = LAMA_SIZE * LAMA_SIZE
            val imgArr = FloatArray(3 * plane)
            val maskArr = FloatArray(plane)

            for (i in 0 until plane) {
                val p = imgPx[i]
                imgArr[0 * plane + i] = ((p shr 16) and 0xFF) / 255f
                imgArr[1 * plane + i] = ((p shr 8) and 0xFF) / 255f
                imgArr[2 * plane + i] = (p and 0xFF) / 255f

                val m = maskPx[i]
                val lum = (((m shr 16) and 0xFF) + ((m shr 8) and 0xFF) + (m and 0xFF)) / 3
                maskArr[i] = if (lum > 128) 1f else 0f
            }

            imgTensor = OnnxTensor.createTensor(
                env, FloatBuffer.wrap(imgArr),
                longArrayOf(1, 3, LAMA_SIZE.toLong(), LAMA_SIZE.toLong())
            )
            maskTensor = OnnxTensor.createTensor(
                env, FloatBuffer.wrap(maskArr),
                longArrayOf(1, 1, LAMA_SIZE.toLong(), LAMA_SIZE.toLong())
            )

            val inputNames = session.inputNames.toList()
            val inputs = mutableMapOf<String, OnnxTensor>()
            inputs[inputNames[0]] = imgTensor!!
            if (inputNames.size >= 2) inputs[inputNames[1]] = maskTensor!!

            output = session.run(inputs)
            val outTensor = output[0] as OnnxTensor
            val outBuf = outTensor.floatBuffer
            val outShape = outTensor.info.shape

            val outC = outShape[1].toInt()
            val outH = outShape[2].toInt()
            val outW = outShape[3].toInt()
            val outPlane = outH * outW
            val totalFloats = outC * outPlane

            val floats = FloatArray(totalFloats)
            outBuf.rewind()
            outBuf.get(floats)

            var minV = Float.MAX_VALUE
            for (v in floats) if (v < minV) minV = v
            val needsRescale = minV < -0.1f

            val outBmp = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
            val outPx = IntArray(outPlane)
            for (i in 0 until outPlane) {
                fun ch(c: Int): Int {
                    val raw = floats[c * outPlane + i]
                    val n = if (needsRescale) (raw + 1f) / 2f else raw
                    return (n * 255f).toInt().coerceIn(0, 255)
                }
                val r = ch(0); val g = ch(1); val b = ch(2)
                val a = if (outC >= 4) ch(3) else 255
                outPx[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
            }
            outBmp.setPixels(outPx, 0, outW, 0, 0, outW, outH)

            return Bitmap.createScaledBitmap(outBmp, image.width, image.height, true)
        } catch (e: Throwable) {
            Log.e(TAG, "runLaMa failed", e)
            return null
        } finally {
            try { output?.close() } catch (_: Throwable) {}
            try { maskTensor?.close() } catch (_: Throwable) {}
            try { imgTensor?.close() } catch (_: Throwable) {}
        }
    }

    private fun runEsrgan(image: Bitmap, factor: Int): Bitmap? {
        val session = esrganSession ?: return null

        var input: OnnxTensor? = null
        var output: OrtSession.Result? = null

        try {
            var w = image.width
            var h = image.height
            if (w > ESRGAN_MAX_DIM || h > ESRGAN_MAX_DIM) {
                val s = min(ESRGAN_MAX_DIM.toFloat() / w, ESRGAN_MAX_DIM.toFloat() / h)
                w = (w * s).toInt()
                h = (h * s).toInt()
            }
            w = ((w / 32) * 32).coerceAtLeast(32)
            h = ((h / 32) * 32).coerceAtLeast(32)

            val resized = safeResize(image, w, h)
            val plane = w * h
            val px = IntArray(plane)
            resized.getPixels(px, 0, w, 0, 0, w, h)

            val arr = FloatArray(3 * plane)
            for (i in 0 until plane) {
                val p = px[i]
                arr[0 * plane + i] = ((p shr 16) and 0xFF) / 255f
                arr[1 * plane + i] = ((p shr 8) and 0xFF) / 255f
                arr[2 * plane + i] = (p and 0xFF) / 255f
            }

            input = OnnxTensor.createTensor(
                env, FloatBuffer.wrap(arr),
                longArrayOf(1, 3, h.toLong(), w.toLong())
            )

            val inputName = session.inputNames.first()
            output = session.run(mapOf(inputName to input!!))
            val outTensor = output[0] as OnnxTensor
            val outShape = outTensor.info.shape
            val outH = outShape[2].toInt()
            val outW = outShape[3].toInt()
            val outPlane = outH * outW
            val total = 3 * outPlane

            val floats = FloatArray(total)
            outTensor.floatBuffer.rewind()
            outTensor.floatBuffer.get(floats)

            var minV = Float.MAX_VALUE
            for (v in floats) if (v < minV) minV = v
            val needsRescale = minV < -0.1f

            val outBmp = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
            val outPx = IntArray(outPlane)
            for (i in 0 until outPlane) {
                fun ch(c: Int): Int {
                    val raw = floats[c * outPlane + i]
                    val n = if (needsRescale) (raw + 1f) / 2f else raw
                    return (n * 255f).toInt().coerceIn(0, 255)
                }
                outPx[i] = (255 shl 24) or (ch(0) shl 16) or (ch(1) shl 8) or ch(2)
            }
            outBmp.setPixels(outPx, 0, outW, 0, 0, outW, outH)

            return outBmp
        } catch (e: Throwable) {
            Log.e(TAG, "runEsrgan failed", e)
            return null
        } finally {
            try { output?.close() } catch (_: Throwable) {}
            try { input?.close() } catch (_: Throwable) {}
        }
    }

    private fun decodeBitmap(path: String): Bitmap? {
        return try {
            val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, opts)
            val maxDim = 4096
            var sample = 1
            while (opts.outWidth / sample > maxDim || opts.outHeight / sample > maxDim) {
                sample *= 2
            }
            val opts2 = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeFile(path, opts2)
        } catch (e: Throwable) {
            Log.e(TAG, "decodeBitmap failed", e)
            null
        }
    }

    private fun safeResize(src: Bitmap, w: Int, h: Int): Bitmap {
        return try {
            if (src.width == w && src.height == h) src
            else Bitmap.createScaledBitmap(src, w, h, true)
        } catch (e: Throwable) {
            val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            val paint = Paint().apply {
                isFilterBitmap = true
                isAntiAlias = true
            }
            canvas.drawBitmap(src, null, android.graphics.Rect(0, 0, w, h), paint)
            out
        }
    }

    private fun solidBitmap(w: Int, h: Int, color: Int): Bitmap =
        Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).apply { eraseColor(color) }
}
