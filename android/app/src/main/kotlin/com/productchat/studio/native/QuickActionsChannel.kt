package com.productchat.studio.native

import android.content.Context
import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.productchat.studio.R

class QuickActionsChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object { const val CHANNEL = "com.productchat/quick_actions"; private const val MAX_SHORTCUTS = 4 }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) { "setShortcuts" -> handleSetShortcuts(call, result); "clearShortcuts" -> handleClear(result); else -> result.notImplemented() }
    }

    private fun handleSetShortcuts(call: MethodCall, result: MethodChannel.Result) {
        try {
            val shortcuts = call.argument<List<Map<String, String>>>("shortcuts") ?: emptyList()
            val list = shortcuts.take(MAX_SHORTCUTS).map { shortcut ->
                val intent = Intent(context, com.productchat.studio.MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    putExtra("shortcut_type", shortcut["type"])
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                ShortcutInfoCompat.Builder(context, shortcut["type"] ?: "unknown")
                    .setShortLabel(shortcut["title"] ?: "")
                    .setLongLabel(shortcut["subtitle"] ?: "")
                    .setIcon(IconCompat.createWithResource(context, R.mipmap.ic_launcher))
                    .setIntent(intent).build()
            }
            ShortcutManagerCompat.setDynamicShortcuts(context, list)
            result.success(true)
        } catch (e: Throwable) { result.error("SHORTCUT_ERROR", e.message, null) }
    }

    private fun handleClear(result: MethodChannel.Result) {
        try { ShortcutManagerCompat.removeAllDynamicShortcuts(context); result.success(true) }
        catch (e: Throwable) { result.error("SHORTCUT_ERROR", e.message, null) }
    }
}
