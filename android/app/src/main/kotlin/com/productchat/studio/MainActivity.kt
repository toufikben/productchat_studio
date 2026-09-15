package com.productchat.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.productchat.aiphotostudio.native.SeikaChannel
import com.productchat.studio.native.MIGanChannel
import com.productchat.studio.native.QwenEditChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val seika = SeikaChannel(this)
        seika.attach(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "productchat/studio/seika"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MIGanChannel.CHANNEL)
            .setMethodCallHandler(MIGanChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QwenEditChannel.CHANNEL)
            .setMethodCallHandler(QwenEditChannel(this))
    }
}
