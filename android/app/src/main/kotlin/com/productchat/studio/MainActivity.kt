package com.productchat.studio

import android.content.Intent
import android.util.Log
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
    companion object {
        private const val SHORTCUT_CHANNEL = "com.productchat/shortcut_intent"
        private const val TAG = "ProductChatMain"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Native AI bridges are optional. A constructor/linker/runtime error
        // in one bridge must not prevent Flutter from reaching its first UI.
        registerSafely("seika") {
            SeikaChannel(this).attach(
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SeikaChannel.CHANNEL)
            )
        }
        registerSafely("migan") { register(flutterEngine, MIGanChannel.CHANNEL, MIGanChannel(this)) }
        registerSafely("modnet") { register(flutterEngine, MODNetChannel.CHANNEL, MODNetChannel(this)) }
        registerSafely("comparison") { register(flutterEngine, ModelComparisonChannel.CHANNEL, ModelComparisonChannel(this)) }
        registerSafely("mobilesam") { register(flutterEngine, MobileSAMChannel.CHANNEL, MobileSAMChannel(this)) }
        registerSafely("qwen") { register(flutterEngine, QwenEditChannel.CHANNEL, QwenEditChannel(this)) }
        registerSafely("quick-actions") { register(flutterEngine, QuickActionsChannel.CHANNEL, QuickActionsChannel(applicationContext)) }
        registerSafely("shortcut-intent") { handleShortcutIntent(intent, flutterEngine) }
    }

    private fun register(
        engine: FlutterEngine,
        channel: String,
        handler: MethodChannel.MethodCallHandler,
    ) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler(handler)
    }

    private inline fun registerSafely(name: String, action: () -> Unit) {
        try {
            action()
        } catch (t: Throwable) {
            Log.e(TAG, "Optional native bridge failed: $name", t)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        flutterEngine?.let { handleShortcutIntent(intent, it) }
    }

    private fun handleShortcutIntent(intent: Intent?, engine: FlutterEngine) {
        val type = intent?.getStringExtra("shortcut_type") ?: return
        try {
            MethodChannel(engine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL)
                .invokeMethod("onShortcut", type)
        } catch (t: Throwable) {
            Log.e(TAG, "Shortcut intent delivery failed", t)
        }
    }
}
