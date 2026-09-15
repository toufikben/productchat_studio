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
 * QwenEditChannel — Native bridge for Qwen-Image-Edit conversational editing.
 * Replaces DreamLite (CC BY-NC → Apache 2.0 commercial license).
 */
class QwenEditChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/qwen_edit"
        private const val INPUT_SIZE = 1024
        private const val TAG = "QwenEditChannel"
    }

    private var session: OrtSession? = null
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> handleLoadModel(call, result)
            "edit" -> handleEdit(call, result)
            "unloadModel" -> handleUnload(result)
            "isLoaded" -> synchronized(lock) { result.success(session != null) }
            else -> result.notImplemented()
        }
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelPath = call.argument<String>("modelPath") ?: return result.error("NO_MODEL", "modelPath required", null)
        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(4)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            }
            synchronized(lock) {
                session?.close()
                session = env.createSession(modelPath, opts)
            }
            result.success(mapOf("ok" to true))
        } catch (e: Throwable) {
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun handleEdit(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("imagePath") ?: return result.error("ARGS", "imagePath required", null)
        val prompt = call.argument<String>("prompt") ?: ""
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_qwen.png")

        try {
            val bitmap = BitmapFactory.decodeFile(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode", null)
            val output = synchronized(lock) { runInference(bitmap, prompt) } ?: bitmap
            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            result.success(mapOf("ok" to true, "outputPath" to outputPath))
        } catch (e: Throwable) {
            Log.e(TAG, "Edit failed", e)
            result.error("EDIT_ERROR", e.message, null)
        }
    }

    private fun runInference(image: Bitmap, prompt: String): Bitmap? {
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

        val imgTensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(input),
            longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong())
        )

        // Tokenize prompt (simplified — for production, use CLIP tokenizer)
        val tokens = IntArray(77) { 0 }
        val words = prompt.lowercase().split(Regex("\\s+"))
        for (i in words.indices.take(77)) {
            tokens[i] = words[i].hashCode() and 0xFFFF
        }
        val tokensFloat = FloatArray(77) { tokens[it].toFloat() }
        val promptTensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(tokensFloat), longArrayOf(1, 77)
        )

        val inputs = mapOf(
            session.inputNames.elementAt(0) to imgTensor,
            session.inputNames.elementAtOrNull(1)?.let { it to promptTensor }
        ).filterValues { it != null }.mapValues { it.value!! }

        val result = session.run(inputs)
        val outputTensor = result[0] as OnnxTensor
        val outBuffer = outputTensor.floatBuffer
        outBuffer.rewind()
        val outFloats = FloatArray(3 * plane)
        outBuffer.get(outFloats)

        val outBitmap = Bitmap.createBitmap(INPUT_SIZE, INPUT_SIZE, Bitmap.Config.ARGB_8888)
        val outPixels = IntArray(plane)
        for (i in 0 until plane) {
            val r = (outFloats[0 * plane + i] * 255).toInt().coerceIn(0, 255)
            val g = (outFloats[1 * plane + i] * 255).toInt().coerceIn(0, 255)
            val b = (outFloats[2 * plane + i] * 255).toInt().coerceIn(0, 255)
            outPixels[i] = (255 shl 24) or (r shl 16) or (g shl 8) or b
        }
        outBitmap.setPixels(outPixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        imgTensor.close()
        promptTensor.close()
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
