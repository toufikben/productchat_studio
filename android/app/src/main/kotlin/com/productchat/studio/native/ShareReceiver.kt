package com.productchat.studio.native

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * ShareReceiver — Handles images shared INTO the app from other apps.
 * Registered as ActivityResultListener for ACTION_SEND intents.
 */
class ShareReceiver : PluginRegistry.ActivityResultListener {

    private var pendingResult: MethodChannel.Result? = null
    private var pendingImagePath: String? = null

    companion object {
        const val CHANNEL = "com.productchat/share"
    }

    fun setPendingImage(path: String?) {
        pendingImagePath = path
    }

    fun consumePendingImage(): String? {
        val p = pendingImagePath
        pendingImagePath = null
        return p
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPendingImage" -> {
                result.success(consumePendingImage())
            }
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == 1001 && resultCode == Activity.RESULT_OK) {
            val uri = data?.data
            if (uri != null) {
                pendingImagePath = uri.toString()
                pendingResult?.success(uri.toString())
                pendingResult = null
                return true
            }
        }
        return false
    }
}
