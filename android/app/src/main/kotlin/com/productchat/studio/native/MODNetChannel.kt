package com.productchat.studio.native

import ai.onnxruntime.*
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.nio.FloatBuffer

/**
 * MODNetChannel — Portrait/product matting via MODNet.
 *
 * MODNet is optimized for alpha matte extraction (better edges than MI-GAN
 * for hair, glass, fabric).
 *
 * Model: https://github.com/ZHKKKe/MODNet
 * Size: ~25 MB ONNX
 * Input: [1, 3, 512, 512], range [0, 1]
 * Output: [1, 1, 512, 512], alpha in [0, 1]
 */
class MODNetChannel(private val context: Context)
    : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/modnet"
        private const val INPUT_SIZE = 512
        private const val TAG = "MODNetChannel"
    }

    private var session: OrtSession? = null
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> handleLoadModel(call, result)
            "extractAlpha" -> handleExtractAlpha(call, result)
            "unloadModel" -> handleUnload(result)
            "isLoaded" -> synchronized(lock) { result.success(session != null) }
            else -> result.notImplemented()
        }
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelPath = call.argument<String>("modelPath")
            ?: return result.error("NO_MODEL", "modelPath required", null)

        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(4)
                setInterOpNumThreads(1)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                try { addNnapi() } catch (_: Throwable) {}
            }

            synchronized(lock) {
                session?.close()
                session = env.createSession(modelPath, opts)
            }
            result.success(mapOf("ok" to true, "modelType" to "modnet"))
        } catch (e: Throwable) {
            Log.e(TAG, "loadModel failed", e)
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun handleExtractAlpha(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
            ?: return result.error("INVALID_ARGS", "path required", null)
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_modnet.png")

        try {
            val bmp = decodeBitmap(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode", null)

            val output = synchronized(lock) { runInference(bmp) }
                ?: return result.error(
                    "INFERENCE_FAIL",
                    "MODNet inference failed",
                    null,
                )

            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf(
                "ok" to true,
                "outputPath" to outputPath,
                "width" to output.width,
                "height" to output.height,
                "mode" to "modnet_onnx",
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "extractAlpha failed", e)
            result.error("PROCESSING_ERROR", e.message, null)
        }
    }

    private fun runInference(image: Bitmap): Bitmap? {
        val s = session ?: return null

        // 1. Resize
        val resized = Bitmap.createScaledBitmap(
            image, INPUT_SIZE, INPUT_SIZE, true
        )
        val plane = INPUT_SIZE * INPUT_SIZE
        val pixels = IntArray(plane)
        resized.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        // 2. Input tensor [1, 3, 512, 512], [0, 1]
        val input = FloatArray(3 * plane)
        for (i in 0 until plane) {
            val p = pixels[i]
            input[0 * plane + i] = ((p shr 16) and 0xFF) / 255f
            input[1 * plane + i] = ((p shr 8) and 0xFF) / 255f
            input[2 * plane + i] = (p and 0xFF) / 255f
        }

        val tensor = OnnxTensor.createTensor(
            env,
            FloatBuffer.wrap(input),
            longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong()),
        )

        // 3. Run
        val result = s.run(mapOf(s.inputNames.first() to tensor))
        val outTensor = result[0] as OnnxTensor
        val outBuffer = outTensor.floatBuffer
        outBuffer.rewind()

        val floats = FloatArray(plane)
        outBuffer.get(floats)

        // 4. Build output: RGB (original) + Alpha (from MODNet)
        val outBitmap = Bitmap.createBitmap(
            INPUT_SIZE, INPUT_SIZE, Bitmap.Config.ARGB_8888
        )
        val outPx = IntArray(plane)

        for (i in 0 until plane) {
            val alpha = (floats[i].coerceIn(0f, 1f) * 255).toInt()
            val p = pixels[i]
            val r = (p shr 16) and 0xFF
            val g = (p shr 8) and 0xFF
            val b = p and 0xFF
            outPx[i] = (alpha shl 24) or (r shl 16) or (g shl 8) or b
        }
        outBitmap.setPixels(outPx, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        tensor.close()
        result.close()

        // 5. Scale back
        return Bitmap.createScaledBitmap(
            outBitmap, image.width, image.height, true
        )
    }

    private fun handleUnload(result: MethodChannel.Result) {
        synchronized(lock) {
            session?.close()
            session = null
        }
        result.success(true)
    }

    private fun decodeBitmap(path: String): Bitmap? {
        return try {
            val opts = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, opts)

            val maxDim = 4096
            var sample = 1
            while (opts.outWidth / sample > maxDim ||
                opts.outHeight / sample > maxDim
            ) {
                sample *= 2
            }

            val opts2 = BitmapFactory.Options().apply {
                inSampleSize = sample
            }
            BitmapFactory.decodeFile(path, opts2)
        } catch (e: Throwable) {
            Log.e(TAG, "decodeBitmap failed", e)
            null
        }
    }
}
