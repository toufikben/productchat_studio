package com.productchat.aiphotostudio.native

import android.graphics.Bitmap
import java.util.ArrayDeque
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt
import kotlin.random.Random

/**
 * Local PatchMatch-assisted background segmentation.
 *
 * The algorithm starts from corner background seeds, grows a conservative
 * connected background mask, then refines uncertain boundary pixels by
 * propagation/random-search patch matching against known background patches.
 * It returns an ARGB bitmap with the matched background made transparent.
 * No network, model download, or external service is used.
 */
class PatchMatchRemover {
    companion object {
        private const val PATCH_RADIUS = 1
        private const val COLOR_THRESHOLD = 58.0
        private const val PATCH_THRESHOLD = 34.0
        private const val ITERATIONS = 2
    }

    fun remove(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        require(width > 2 && height > 2) { "Image is too small for PatchMatch" }

        val pixels = IntArray(width * height)
        source.getPixels(pixels, 0, width, 0, 0, width, height)
        val background = connectedBackground(pixels, width, height)
        val references = initialReferences(pixels, background, width, height)
        refineReferences(pixels, background, references, width, height)

        val output = source.copy(Bitmap.Config.ARGB_8888, true)
        val result = IntArray(pixels.size)
        for (y in 0 until height) {
            for (x in 0 until width) {
                val index = y * width + x
                val pixel = pixels[index]
                val transparent = background[index] &&
                    patchDistance(pixels, references[index], x, y, width, height) <= PATCH_THRESHOLD
                result[index] = if (transparent) pixel and 0x00ffffff else pixel
            }
        }
        output.setPixels(result, 0, width, 0, 0, width, height)
        return output
    }

    private fun connectedBackground(pixels: IntArray, width: Int, height: Int): BooleanArray {
        val background = BooleanArray(pixels.size)
        val queue = ArrayDeque<Int>()
        val seedColors = intArrayOf(
            pixels[0],
            pixels[width - 1],
            pixels[(height - 1) * width],
            pixels[height * width - 1],
        )
        val reference = averageColor(seedColors)
        val threshold = max(COLOR_THRESHOLD, cornerSpread(seedColors) * 2.2)

        fun enqueue(index: Int) {
            if (index >= 0 && index < background.size && !background[index]) {
                background[index] = true
                queue.add(index)
            }
        }
        for (x in 0 until width) {
            enqueue(x)
            enqueue((height - 1) * width + x)
        }
        for (y in 0 until height) {
            enqueue(y * width)
            enqueue(y * width + width - 1)
        }

        while (queue.isNotEmpty()) {
            val index = queue.removeFirst()
            val x = index % width
            val y = index / width
            val neighbors = intArrayOf(
                if (x > 0) index - 1 else -1,
                if (x + 1 < width) index + 1 else -1,
                if (y > 0) index - width else -1,
                if (y + 1 < height) index + width else -1,
            )
            for (neighbor in neighbors) {
                if (neighbor >= 0 && !background[neighbor] &&
                    colorDistance(pixels[neighbor], reference) <= threshold
                ) {
                    enqueue(neighbor)
                }
            }
        }
        return background
    }

    private fun initialReferences(
        pixels: IntArray,
        background: BooleanArray,
        width: Int,
        height: Int,
    ): IntArray {
        val references = IntArray(pixels.size) { -1 }
        val seeds = intArrayOf(0, width - 1, (height - 1) * width, height * width - 1)
        for (index in pixels.indices) {
            if (!background[index]) continue
            var best = seeds[0]
            var bestDistance = Double.MAX_VALUE
            for (seed in seeds) {
                val distance = colorDistance(pixels[index], pixels[seed])
                if (distance < bestDistance) {
                    bestDistance = distance
                    best = seed
                }
            }
            references[index] = best
        }
        return references
    }

    private fun refineReferences(
        pixels: IntArray,
        background: BooleanArray,
        references: IntArray,
        width: Int,
        height: Int,
    ) {
        val random = Random(17)
        for (iteration in 0 until ITERATIONS) {
            val yRange = if (iteration % 2 == 0) 0 until height else (height - 1 downTo 0)
            val xRange = if (iteration % 2 == 0) 0 until width else (width - 1 downTo 0)
            for (y in yRange) {
                for (x in xRange) {
                    val index = y * width + x
                    if (!background[index]) continue
                    var best = references[index]
                    var bestScore = patchDistance(pixels, best, x, y, width, height)
                    val neighboring = intArrayOf(
                        if (x > 0) references[index - 1] else -1,
                        if (x + 1 < width) references[index + 1] else -1,
                        if (y > 0) references[index - width] else -1,
                        if (y + 1 < height) references[index + width] else -1,
                    )
                    for (candidate in neighboring) {
                        if (candidate < 0) continue
                        val score = patchDistance(pixels, candidate, x, y, width, height)
                        if (score < bestScore) {
                            best = candidate
                            bestScore = score
                        }
                    }
                    var radius = max(width, height)
                    while (radius > 1) {
                        val candidateX = min(width - 1, max(0, x + random.nextInt(-radius, radius + 1)))
                        val candidateY = min(height - 1, max(0, y + random.nextInt(-radius, radius + 1)))
                        val candidate = candidateY * width + candidateX
                        if (background[candidate]) {
                            val score = patchDistance(pixels, candidate, x, y, width, height)
                            if (score < bestScore) {
                                best = candidate
                                bestScore = score
                            }
                        }
                        radius /= 2
                    }
                    references[index] = best
                }
            }
        }
    }

    private fun patchDistance(
        pixels: IntArray,
        reference: Int,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
    ): Double {
        if (reference < 0) return Double.MAX_VALUE
        val referenceX = reference % width
        val referenceY = reference / width
        var total = 0.0
        var count = 0
        for (dy in -PATCH_RADIUS..PATCH_RADIUS) {
            for (dx in -PATCH_RADIUS..PATCH_RADIUS) {
                val x1 = min(width - 1, max(0, x + dx))
                val y1 = min(height - 1, max(0, y + dy))
                val x2 = min(width - 1, max(0, referenceX + dx))
                val y2 = min(height - 1, max(0, referenceY + dy))
                total += colorDistance(pixels[y1 * width + x1], pixels[y2 * width + x2])
                count++
            }
        }
        return total / count
    }

    private fun colorDistance(first: Int, second: Int): Double {
        val dr = ((first shr 16) and 0xff) - ((second shr 16) and 0xff)
        val dg = ((first shr 8) and 0xff) - ((second shr 8) and 0xff)
        val db = (first and 0xff) - (second and 0xff)
        return sqrt((dr * dr + dg * dg + db * db).toDouble())
    }

    private fun averageColor(colors: IntArray): Int {
        val red = colors.sumOf { (it shr 16) and 0xff } / colors.size
        val green = colors.sumOf { (it shr 8) and 0xff } / colors.size
        val blue = colors.sumOf { it and 0xff } / colors.size
        return (0xff shl 24) or (red shl 16) or (green shl 8) or blue
    }

    private fun cornerSpread(colors: IntArray): Double {
        val average = averageColor(colors)
        return colors.map { colorDistance(it, average) }.average()
    }
}
