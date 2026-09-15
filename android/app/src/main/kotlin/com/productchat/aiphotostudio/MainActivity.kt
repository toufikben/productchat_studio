package com.productchat.aiphotostudio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.productchat.aiphotostudio.native.SeikaChannel
import com.productchat.studio.native.MIGanChannel
import com.productchat.studio.native.QwenEditChannel
import com.productchat.studio.native.SeikaChannel as NativeSeikaChannel

class MainActivity : FlutterActivity() {
    private val channelName = "productchat/studio/seika"
    private lateinit var seika: SeikaChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        seika = SeikaChannel(this)
        seika.attach(channel)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeSeikaChannel.CHANNEL,
        ).setMethodCallHandler(NativeSeikaChannel(this))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MIGanChannel.CHANNEL,
        ).setMethodCallHandler(MIGanChannel(this))
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QwenEditChannel.CHANNEL,
        ).setMethodCallHandler(QwenEditChannel(this))
    }

    override fun onDestroy() {
        if (::seika.isInitialized) seika.close()
        super.onDestroy()
    }
}
