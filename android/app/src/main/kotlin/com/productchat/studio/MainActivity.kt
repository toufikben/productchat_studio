package com.productchat.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "productchat/studio/seika"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                // MI-GAN/LaMa native implementations plug in here. Until they
                // are shipped, fail explicitly instead of returning fake paths.
                result.error(
                    "NOT_IMPLEMENTED",
                    "Seika operation '${call.method}' is not implemented yet.",
                    null
                )
            }
    }
}
