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
 * MIGanChannel — MI-GAN background removal with verified tensor contracts.
 *
 * Tensor Contract (verified against SAIL-MIGAN model):
 *   Input image:
 *     name: "image" (or first input)
 *     shape: [1, 3, H, W] with H=W=512
 *     type: float32
 *     range: [-1.0, 1.0]  ← MI-GAN expects [-1, 1], not [0, 1]
 *   Output:
 *     shape: [1, 1, H, W] OR [1, 4, H, W]
 *     type: float32
 *     range: [0.0, 1.0] (alpha mask)
 */
class MIGanChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/migan"
        private const val INPUT_SIZE = 512
        private const val TAG = "MIGanChannel"
    }

    private var session: OrtSession? = null
    private var inputName: String = "image"
    private var inputShape: LongArray = longArrayOf(1, 3, 512, 512)
    private val env: OrtEnvironment = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> handleLoadModel(call, result)
            "removeBg" -> handleRemoveBg(call, result)
            "inspectContract" -> handleInspectContract(result)
            "unloadModel" -> handleUnload(result)
            "isLoaded" -> synchronized(lock) { result.success(session != null) }
            else -> result.notImplemented()
        }
    }

    /**
     * Load model + inspect tensor contract.
     */
    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val modelPath = call.argument<String>("modelPath")
            ?: return result.error("NO_MODEL", "modelPath required", null)

        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(4)
                setInterOpNumThreads(1)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                try {
                    addConfigEntry("session.intra_op.allow_spinning", "0")
                } catch (_: Throwable) {}
                try { addNnapi() } catch (t: Throwable) {
                    Log.w(TAG, "NNAPI unavailable: ${t.message}")
                }
            }

            synchronized(lock) {
                session?.close()
                session = env.createSession(modelPath, opts)

                // ─── اكتشاف الـ contract ───
                val s = session!!
                inputName = s.inputNames.first()

                val info = s.inputInfo[inputName]
                val tensorInfo = info?.info as? TensorInfo
                val shape = tensorInfo?.shape ?: longArrayOf(1, 3, 512, 512)
                inputShape = shape

                Log.i(TAG, "Input: $inputName, shape=${shape.contentToString()}")
                Log.i(TAG, "Outputs: ${s.outputNames.toList()}")
            }

            result.success(mapOf(
                "ok" to true,
                "inputName" to inputName,
                "inputShape" to inputShape.toList(),
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "loadModel failed", e)
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    /**
     * Inspect and return tensor contract.
     */
    private fun handleInspectContract(result: MethodChannel.Result) {
        val s = session
            ?: return result.error("NO_SESSION", "Model not loaded", null)

        try {
            val contract = mutableMapOf<String, Any>()

            for (name in s.inputNames) {
                val info = s.inputInfo[name]?.info as? TensorInfo
                contract["input_$name"] = mapOf(
                    "shape" to (info?.shape?.toList() ?: emptyList<Long>()),
                    "type" to (info?.type?.toString() ?: "unknown"),
                )
            }

            for (name in s.outputNames) {
                val info = s.outputInfo[name]?.info as? TensorInfo
                contract["output_$name"] = mapOf(
                    "shape" to (info?.shape?.toList() ?: emptyList<Long>()),
                    "type" to (info?.type?.toString() ?: "unknown"),
                )
            }

            result.success(contract)
        } catch (e: Throwable) {
            result.error("INSPECT_ERROR", e.message, null)
        }
    }

    /**
     * Remove background — with verified [-1, 1] normalization.
     */
    private fun handleRemoveBg(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
            ?: return result.error("INVALID_ARGS", "path required", null)

        val outputPath = path.replace(Regex("\\.[^.]+$"), "_migan.png")

        try {
            val bitmap = decodeBitmap(path)
                ?: return result.error("DECODE_FAIL", "Cannot decode", null)

            val output = synchronized(lock) { runInference(bitmap) }
                ?: return result.error("INFERENCE_FAIL", "Inference failed", null)

            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf(
                "ok" to true,
                "outputPath" to outputPath,
                "width" to output.width,
                "height" to output.height,
                "mode" to "migan_onnx",  // ← لا fallback
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "removeBg failed", e)
            result.error("PROCESSING_ERROR", e.message, null)
        }
    }

    /**
     * Run actual ONNX inference.
     *
     * Key differences from previous version:
     *   • Normalizes to [-1, 1] (MI-GAN contract)
     *   • Handles both [1,1,H,W] and [1,4,H,W] output
     *   • Resizes result back to original dimensions
     */
    private fun runInference(image: Bitmap): Bitmap? {
        val s = session ?: return null

        // 1. Resize to contract size
        val resized = Bitmap.createScaledBitmap(
            image, INPUT_SIZE, INPUT_SIZE, true
        )
        val plane = INPUT_SIZE * INPUT_SIZE
        val pixels = IntArray(plane)
        resized.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        // 2. Prepare input: NCHW, [-1, 1] range
        val input = FloatArray(3 * plane)
        for (i in 0 until plane) {
            val p = pixels[i]
            // MI-GAN expects [-1, 1] not [0, 1]
            input[0 * plane + i] = ((p shr 16) and 0xFF) / 127.5f - 1f
            input[1 * plane + i] = ((p shr 8) and 0xFF) / 127.5f - 1f
            input[2 * plane + i] = (p and 0xFF) / 127.5f - 1f
        }

        // 3. Create tensor
        val tensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(input), inputShape
        )

        // 4. Run
        val result = s.run(mapOf(inputName to tensor))
        val outputTensor = result[0] as OnnxTensor
        val outShape = outputTensor.info.shape
        val channels = outShape[1].toInt()
        val outH = outShape[2].toInt()
        val outW = outShape[3].toInt()
        val outPlane = outH * outW

        // 5. Read output (bulk read for speed)
        val outBuffer = outputTensor.floatBuffer
        outBuffer.rewind()
        val floats = FloatArray(channels * outPlane)
        outBuffer.get(floats)

        // 6. Build output bitmap
        val outBitmap = Bitmap.createBitmap(
            outW, outH, Bitmap.Config.ARGB_8888
        )
        val outPixels = IntArray(outPlane)

        for (i in 0 until outPlane) {
            // A one-channel contract is an alpha mask; preserve RGB from input.
            val source = pixels[(i * pixels.size / outPlane).coerceIn(0, pixels.lastIndex)]
            val r = if (channels >= 4) (floats[i].coerceIn(0f, 1f) * 255).toInt()
                    else (source shr 16) and 0xFF
            val g = if (channels >= 4) (floats[outPlane + i].coerceIn(0f, 1f) * 255).toInt()
                    else (source shr 8) and 0xFF
            val b = if (channels >= 4) (floats[2 * outPlane + i].coerceIn(0f, 1f) * 255).toInt()
                    else source and 0xFF

            // Alpha from model (channel 3 if exists, else channel 0)
            val alpha = if (channels >= 4) {
                (floats[3 * outPlane + i].coerceIn(0f, 1f) * 255).toInt()
            } else if (channels == 1) {
                (floats[0 * outPlane + i].coerceIn(0f, 1f) * 255).toInt()
            } else {
                255
            }

            outPixels[i] = (alpha shl 24) or (r shl 16) or (g shl 8) or b
        }
        outBitmap.setPixels(outPixels, 0, outW, 0, 0, outW, outH)

        // 7. Cleanup
        tensor.close()
        result.close()

        // 8. Scale back to original size
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
