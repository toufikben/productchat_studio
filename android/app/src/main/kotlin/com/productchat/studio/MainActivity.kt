package com.productchat.studio

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.productchat.studio.native.SeikaChannel
import com.productchat.studio.native.MobileSAMChannel
import com.productchat.studio.native.ModelComparisonChannel
import com.productchat.studio.native.MODNetChannel
import com.productchat.studio.native.MIGanChannel
import com.productchat.studio.native.QwenEditChannel
import com.productchat.studio.native.QuickActionsChannel

class MainActivity : FlutterActivity() {
    companion object { private const val SHORTCUT_CHANNEL = "com.productchat/shortcut_intent" }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val seika = SeikaChannel(this)
        seika.attach(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "productchat/studio/seika"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MIGanChannel.CHANNEL)
            .setMethodCallHandler(MIGanChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MODNetChannel.CHANNEL)
            .setMethodCallHandler(MODNetChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ModelComparisonChannel.CHANNEL)
            .setMethodCallHandler(ModelComparisonChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MobileSAMChannel.CHANNEL)
            .setMethodCallHandler(MobileSAMChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QwenEditChannel.CHANNEL)
            .setMethodCallHandler(QwenEditChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QuickActionsChannel.CHANNEL)
            .setMethodCallHandler(QuickActionsChannel(applicationContext))
        handleShortcutIntent(intent, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        flutterEngine?.let { handleShortcutIntent(intent, it) }
    }

    private fun handleShortcutIntent(intent: Intent?, engine: FlutterEngine) {
        val type = intent?.getStringExtra("shortcut_type") ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL)
            .invokeMethod("onShortcut", type)
    }
}
