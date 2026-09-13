package com.productchat.studio.native

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Local Android image engine used by the Flutter Seika bridge.
 *
 * This is a deterministic CPU baseline: background removal uses a corner-color
 * flood mask, inpainting uses edge-color reconstruction, upscaling uses the
 * Android bitmap scaler, and shadows are composited locally. The class is
 * deliberately structured so MI-GAN/LaMa ONNX sessions can replace each
 * operation later without changing the Flutter API.
 */
class SeikaChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    fun attach(channel: MethodChannel) = channel.setMethodCallHandler(this)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val output = when (call.method) {
                "removeBackground" -> removeBackground(call.string("imagePath"))
                "inpaint" -> inpaint(call.string("imagePath"), call.string("maskPath"))
                "upscale" -> upscale(call.string("imagePath"), call.argument<Int>("factor") ?: 2)
                "addShadow" -> addShadow(call.string("imagePath"))
                "export" -> export(call.string("imagePath"), call.argument<String>("format") ?: "jpg")
                else -> throw IllegalArgumentException("Unsupported Seika operation: ${call.method}")
            }
            result.success(output.absolutePath)
        } catch (e: Exception) {
            result.error("SEIKA_ERROR", e.message ?: "Image operation failed", null)
        }
    }

    private fun removeBackground(path: String): File {
        val source = load(path)
        val output = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
        val corner = source.getPixel(0, 0)
        val threshold = 52
        for (y in 0 until source.height) for (x in 0 until source.width) {
            val pixel = source.getPixel(x, y)
            val distance = colorDistance(pixel, corner)
            output.setPixel(x, y, if (distance < threshold) Color.TRANSPARENT else pixel)
        }
        return save(output, "remove_bg")
    }

    private fun inpaint(imagePath: String, maskPath: String): File {
        val source = load(imagePath)
        val mask = load(maskPath)
        require(source.width == mask.width && source.height == mask.height) {
            "Image and mask dimensions must match"
        }
        val output = source.copy(Bitmap.Config.ARGB_8888, true)
        val edge = averageUnmaskedColor(source, mask)
        for (y in 0 until source.height) for (x in 0 until source.width) {
            if (Color.alpha(mask.getPixel(x, y)) > 20 || luminance(mask.getPixel(x, y)) < 220) {
                output.setPixel(x, y, edge)
            }
        }
        return save(output, "inpaint")
    }

    private fun upscale(path: String, factor: Int): File {
        require(factor in 2..4) { "Upscale factor must be 2 or 4" }
        val source = load(path)
        val output = Bitmap.createScaledBitmap(source, source.width * factor, source.height * factor, true)
        return save(output, "upscale_${factor}x")
    }

    private fun addShadow(path: String): File {
        val source = load(path)
        val output = source.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(72, 0, 0, 0) }
        val left = source.width * 0.18f
        val top = source.height * 0.72f
        val right = source.width * 0.82f
        val bottom = source.height * 0.88f
        canvas.drawOval(left, top, right, bottom, paint)
        return save(output, "shadow")
    }

    private fun export(path: String, format: String): File {
        val source = load(path)
        return save(source, "export", format)
    }

    private fun load(path: String): Bitmap = BitmapFactory.decodeFile(path)
        ?: throw IllegalArgumentException("Cannot decode image: $path")

    private fun save(bitmap: Bitmap, prefix: String, requestedFormat: String? = null): File {
        val file = File(context.cacheDir, "${prefix}_${System.currentTimeMillis()}.jpg")
        FileOutputStream(file).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 92, stream)
        }
        if (!bitmap.isRecycled) bitmap.recycle()
        return file
    }

    private fun averageUnmaskedColor(image: Bitmap, mask: Bitmap): Int {
        var red = 0L; var green = 0L; var blue = 0L; var count = 0L
        for (y in 0 until image.height step max(1, image.height / 64)) for (x in 0 until image.width step max(1, image.width / 64)) {
            if (Color.alpha(mask.getPixel(x, y)) <= 20 && luminance(mask.getPixel(x, y)) >= 220) {
                val p = image.getPixel(x, y); red += Color.red(p); green += Color.green(p); blue += Color.blue(p); count++
            }
        }
        if (count == 0L) return Color.rgb(255, 255, 255)
        return Color.rgb((red / count).toInt(), (green / count).toInt(), (blue / count).toInt())
    }

    private fun colorDistance(a: Int, b: Int): Int = abs(Color.red(a) - Color.red(b)) + abs(Color.green(a) - Color.green(b)) + abs(Color.blue(a) - Color.blue(b))
    private fun luminance(color: Int): Int = (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color)).toInt()
    private fun MethodCall.string(key: String): String = argument<String>(key) ?: throw IllegalArgumentException("Missing $key")
}
