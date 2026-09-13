package com.productchat.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.productchat.studio.native.SeikaChannel

class MainActivity : FlutterActivity() {
    private val channelName = "productchat/studio/seika"
    private lateinit var seika: SeikaChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        seika = SeikaChannel(this)
        seika.attach(channel)
    }

    override fun onDestroy() {
        if (::seika.isInitialized) seika.close()
        super.onDestroy()
    }
}
