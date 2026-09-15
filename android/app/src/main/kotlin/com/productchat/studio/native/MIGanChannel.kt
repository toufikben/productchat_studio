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
 * MIGanChannel — Native bridge for MI-GAN background removal.
 * Uses ONNX Runtime with NNAPI acceleration when available.
 */
class MIGanChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/migan"
        private const val INPUT_SIZE = 512
        private const val TAG = "MIGanChannel"
    }

    private var session: OrtSession? = null
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> handleLoadModel(call, result)
            "removeBg" -> handleRemoveBg(call, result)
            "unloadModel" -> handleUnload(result)
            "isLoaded" -> synchronized(lock) { result.success(session != null) }
            else -> result.notImplemented()
        }
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelPath = call.argument<String>("modelPath")
        if (modelPath == null) {
            result.error("NO_MODEL", "modelPath required", null)
            return
        }
        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(4)
                setInterOpNumThreads(1)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                try { addNnapi() } catch (t: Throwable) { Log.w(TAG, "NNAPI unavailable") }
            }
            synchronized(lock) {
                session?.close()
                session = env.createSession(modelPath, opts)
            }
            result.success(mapOf("ok" to true, "modelType" to "migan"))
        } catch (e: Throwable) {
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun handleRemoveBg(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("INVALID_ARGS", "path required", null)
            return
        }
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_migan.png")
        try {
            val bitmap = BitmapFactory.decodeFile(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode", null)
            val output = synchronized(lock) { runInference(bitmap) }
                ?: PatchMatchRemover.removeBackground(bitmap)
            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            result.success(mapOf("ok" to true, "outputPath" to outputPath))
        } catch (e: Throwable) {
            result.error("PROCESSING_ERROR", e.message, null)
        }
    }

    private fun runInference(image: Bitmap): Bitmap? {
        val session = session ?: return null
        val resized = Bitmap.createScaledBitmap(image, INPUT_SIZE, INPUT_SIZE, true)
        val plane = INPUT_SIZE * INPUT_SIZE
        val input = FloatArray(3 * plane)
        val pixels = IntArray(plane)
        resized.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        for (i in 0 until plane) {
            val p = pixels[i]
            input[0 * plane + i] = ((p shr 16) and 0xFF) / 255f
            input[1 * plane + i] = ((p shr 8) and 0xFF) / 255f
            input[2 * plane + i] = (p and 0xFF) / 255f
        }

        val tensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(input),
            longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong())
        )
        val result = session.run(mapOf(session.inputNames.first() to tensor))
        val outputTensor = result[0] as OnnxTensor
        val outShape = outputTensor.info.shape
        val channels = outShape[1].toInt()
        val outBuffer = outputTensor.floatBuffer
        outBuffer.rewind()
        val floats = FloatArray(channels * plane)
        outBuffer.get(floats)

        val outBitmap = Bitmap.createBitmap(INPUT_SIZE, INPUT_SIZE, Bitmap.Config.ARGB_8888)
        val outPixels = IntArray(plane)
        for (i in 0 until plane) {
            val r = (floats[0 * plane + i] * 255).toInt().coerceIn(0, 255)
            val g = (floats[1 * plane + i] * 255).toInt().coerceIn(0, 255)
            val b = (floats[2 * plane + i] * 255).toInt().coerceIn(0, 255)
            val a = if (channels >= 4) (floats[3 * plane + i] * 255).toInt().coerceIn(0, 255) else 255
            outPixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
        }
        outBitmap.setPixels(outPixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        tensor.close()
        result.close()

        return Bitmap.createScaledBitmap(outBitmap, image.width, image.height, true)
    }

    private fun handleUnload(result: MethodChannel.Result) {
        synchronized(lock) {
            session?.close()
            session = null
        }
        result.success(true)
    }
}
