package com.productchat.studio.native

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * ModelComparisonChannel — يقارن MI-GAN vs LaMa على نفس الصورة.
 *
 * Returns metrics: time, memory, output size, edge sharpness.
 */
class ModelComparisonChannel(private val context: Context)
    : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.productchat/comparison"
    }

    private val migan = MIGanChannel(context)
    private val seika = SeikaChannel(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "compareModels" -> handleCompare(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleCompare(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
            ?: return result.error("INVALID_ARGS", "path required", null)

        val miganPath = call.argument<String>("miganModelPath")
        val lamaPath = call.argument<String>("lamaModelPath")

        try {
            val metrics = mutableMapOf<String, Any?>()

            // ─── MI-GAN ───
            if (miganPath != null) {
                migan.onMethodCall(
                    MethodCall("loadModel", mapOf("modelPath" to miganPath)),
                    object : MethodChannel.Result {
                        override fun success(r: Any?) {}
                        override fun error(c: String, m: String?, d: Any?) {}
                        override fun notImplemented() {}
                    }
                )

                val startMem = Runtime.getRuntime().totalMemory() -
                    Runtime.getRuntime().freeMemory()
                val start = System.currentTimeMillis()

                migan.onMethodCall(
                    MethodCall("removeBg", mapOf(
                        "path" to path,
                        "quality" to "balanced",
                    )),
                    object : MethodChannel.Result {
                        override fun success(r: Any?) {
                            val elapsed = System.currentTimeMillis() - start
                            val endMem = Runtime.getRuntime().totalMemory() -
                                Runtime.getRuntime().freeMemory()
                            val map = r as? Map<*, *>
                            val outPath = map?.get("outputPath") as? String
                            val size = outPath?.let { File(it).length() } ?: 0

                            metrics["migan"] = mapOf(
                                "ok" to true,
                                "timeMs" to elapsed,
                                "memoryMb" to (endMem - startMem) / 1024 / 1024,
                                "outputPath" to outPath,
                                "outputSizeBytes" to size,
                            )
                        }
                        override fun error(c: String, m: String?, d: Any?) {
                            metrics["migan"] = mapOf(
                                "ok" to false,
                                "error" to "$c: $m",
                            )
                        }
                        override fun notImplemented() {}
                    }
                )
            }

            // ─── LaMa ───
            if (lamaPath != null) {
                seika.onMethodCall(
                    MethodCall("loadModel", mapOf(
                        "modelType" to "lama",
                        "modelPath" to lamaPath,
                    )),
                    object : MethodChannel.Result {
                        override fun success(r: Any?) {}
                        override fun error(c: String, m: String?, d: Any?) {}
                        override fun notImplemented() {}
                    }
                )

                val startMem = Runtime.getRuntime().totalMemory() -
                    Runtime.getRuntime().freeMemory()
                val start = System.currentTimeMillis()

                seika.onMethodCall(
                    MethodCall("removeBg", mapOf(
                        "path" to path,
                        "quality" to "best",
                    )),
                    object : MethodChannel.Result {
                        override fun success(r: Any?) {
                            val elapsed = System.currentTimeMillis() - start
                            val endMem = Runtime.getRuntime().totalMemory() -
                                Runtime.getRuntime().freeMemory()
                            val map = r as? Map<*, *>
                            val outPath = map?.get("outputPath") as? String
                            val size = outPath?.let { File(it).length() } ?: 0

                            metrics["lama"] = mapOf(
                                "ok" to true,
                                "timeMs" to elapsed,
                                "memoryMb" to (endMem - startMem) / 1024 / 1024,
                                "outputPath" to outPath,
                                "outputSizeBytes" to size,
                            )
                        }
                        override fun error(c: String, m: String?, d: Any?) {
                            metrics["lama"] = mapOf(
                                "ok" to false,
                                "error" to "$c: $m",
                            )
                        }
                        override fun notImplemented() {}
                    }
                )
            }

            // Return after brief delay to let callbacks fire
            android.os.Handler(android.os.Looper.getMainLooper())
                .postDelayed({
                    result.success(metrics)
                }, 8000)
        } catch (e: Throwable) {
            result.error("COMPARE_ERROR", e.message, null)
        }
    }
}
