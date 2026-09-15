package com.productchat.studio.native

import ai.onnxruntime.*
import android.content.Context
import android.graphics.*
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.nio.FloatBuffer

/**
 * MobileSAMChannel — Object detection + mask creation.
 *
 * Use case: User taps object → app returns bounding box + mask
 * → feeds into LaMa for inpainting.
 *
 * Contract:
 *   Encoder: [1, 3, 1024, 1024] → [1, 256, 64, 64] embedding
 *   Decoder: embedding + point prompt → mask
 */
class MobileSAMChannel(private val context: Context)
    : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/mobilesam"
        private const val ENCODER_SIZE = 1024
        private const val TAG = "MobileSAM"
    }

    private var encoder: OrtSession? = null
    private var decoder: OrtSession? = null
    private val env = OrtEnvironment.getEnvironment()
    private val lock = Any()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> handleLoadModel(call, result)
            "generateMask" -> handleGenerateMask(call, result)
            "unloadModel" -> handleUnload(result)
            "isLoaded" -> synchronized(lock) {
                result.success(encoder != null && decoder != null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleLoadModel(call: MethodCall, result: MethodChannel.Result) {
        val encoderPath = call.argument<String>("encoderPath")
        val decoderPath = call.argument<String>("decoderPath")

        if (encoderPath == null || decoderPath == null) {
            return result.error(
                "NO_MODEL",
                "encoderPath and decoderPath required",
                null,
            )
        }

        try {
            val opts = OrtSession.SessionOptions().apply {
                setIntraOpNumThreads(4)
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            }
            synchronized(lock) {
                encoder?.close()
                decoder?.close()
                encoder = env.createSession(encoderPath, opts)
                decoder = env.createSession(decoderPath, opts)
            }
            result.success(mapOf("ok" to true))
        } catch (e: Throwable) {
            Log.e(TAG, "loadModel failed", e)
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun handleGenerateMask(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
            ?: return result.error("ARGS", "path required", null)
        val x = call.argument<Double>("x")?.toFloat() ?: 0f
        val y = call.argument<Double>("y")?.toFloat() ?: 0f
        val outputPath = path.replace(Regex("\\.[^.]+$"), "_mask.png")

        try {
            val bmp = BitmapFactory.decodeFile(path)
                ?: return result.error("DECODE", "Cannot decode", null)

            val output = synchronized(lock) {
                generateMask(bmp, x, y)
            } ?: return result.error("INFERENCE", "Mask generation failed", null)

            FileOutputStream(outputPath).use {
                output.compress(Bitmap.CompressFormat.PNG, 100, it)
            }

            result.success(mapOf(
                "ok" to true,
                "outputPath" to outputPath,
                "width" to output.width,
                "height" to output.height,
            ))
        } catch (e: Throwable) {
            Log.e(TAG, "generateMask failed", e)
            result.error("PROCESSING", e.message, null)
        }
    }

    private fun generateMask(image: Bitmap, pointX: Float, pointY: Float): Bitmap? {
        val enc = encoder ?: return null
        val dec = decoder ?: return null

        // 1. Resize for encoder
        val resized = Bitmap.createScaledBitmap(
            image, ENCODER_SIZE, ENCODER_SIZE, true
        )
        val plane = ENCODER_SIZE * ENCODER_SIZE
        val px = IntArray(plane)
        resized.getPixels(px, 0, ENCODER_SIZE, 0, 0, ENCODER_SIZE, ENCODER_SIZE)

        val imgArr = FloatArray(3 * plane)
        for (i in 0 until plane) {
            val p = px[i]
            imgArr[0 * plane + i] = ((p shr 16) and 0xFF) / 255f
            imgArr[1 * plane + i] = ((p shr 8) and 0xFF) / 255f
            imgArr[2 * plane + i] = (p and 0xFF) / 255f
        }

        val imgTensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(imgArr),
            longArrayOf(1, 3, ENCODER_SIZE.toLong(), ENCODER_SIZE.toLong())
        )

        val encResult = enc.run(mapOf(enc.inputNames.first() to imgTensor))
        val embedding = encResult[0] as OnnxTensor

        // 2. Prepare point prompt (normalized to 1024)
        val px1024 = pointX / image.width * ENCODER_SIZE
        val py1024 = pointY / image.height * ENCODER_SIZE

        // SAM decoder inputs: embedding + point_coords + point_labels
        val points = floatArrayOf(px1024, py1024)
        val labels = floatArrayOf(1f)

        val pointsTensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(points), longArrayOf(1, 1, 2)
        )
        val labelsTensor = OnnxTensor.createTensor(
            env, FloatBuffer.wrap(labels), longArrayOf(1, 1)
        )

        val inputs = mutableMapOf<String, OnnxTensor>()
        val inputNames = dec.inputNames.toList()
        inputs[inputNames[0]] = embedding
        if (inputNames.size >= 2) inputs[inputNames[1]] = pointsTensor
        if (inputNames.size >= 3) inputs[inputNames[2]] = labelsTensor

        val decResult = dec.run(inputs)
        val maskTensor = decResult[0] as OnnxTensor
        val maskBuffer = maskTensor.floatBuffer
        maskBuffer.rewind()

        val maskShape = maskTensor.info.shape
        val maskH = maskShape[maskShape.size - 2].toInt()
        val maskW = maskShape[maskShape.size - 1].toInt()
        val maskPlane = maskH * maskW

        val maskFloats = FloatArray(maskPlane)
        maskBuffer.get(maskFloats)

        // 3. Build mask bitmap
        val maskBmp = Bitmap.createBitmap(
            maskW, maskH, Bitmap.Config.ARGB_8888
        )
        val maskPx = IntArray(maskPlane)
        for (i in 0 until maskPlane) {
            val v = maskFloats[i]
            // Threshold at 0
            val alpha = if (v > 0f) 255 else 0
            maskPx[i] = (alpha shl 24) or 0x00FFFFFF
        }
        maskBmp.setPixels(maskPx, 0, maskW, 0, 0, maskW, maskH)

        // Cleanup
        imgTensor.close()
        embedding.close()
        pointsTensor.close()
        labelsTensor.close()
        encResult.close()
        decResult.close()

        return Bitmap.createScaledBitmap(
            maskBmp, image.width, image.height, true
        )
    }

    private fun handleUnload(result: MethodChannel.Result) {
        synchronized(lock) {
            encoder?.close()
            decoder?.close()
            encoder = null
            decoder = null
        }
        result.success(true)
    }
}
