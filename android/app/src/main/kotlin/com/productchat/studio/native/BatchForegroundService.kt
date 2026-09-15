package com.productchat.studio.native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.productchat.studio.R

/**
 * BatchForegroundService — Keeps batch processing alive when app is backgrounded.
 */
class BatchForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "batch_processing"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_BATCH"
        const val ACTION_STOP = "STOP_BATCH"
        const val ACTION_UPDATE = "UPDATE_PROGRESS"
        const val EXTRA_PROGRESS = "progress"
        const val EXTRA_TOTAL = "total"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForeground(NOTIFICATION_ID, buildNotification(0, 0))
            ACTION_UPDATE -> {
                val progress = intent.getIntExtra(EXTRA_PROGRESS, 0)
                val total = intent.getIntExtra(EXTRA_TOTAL, 1)
                updateNotification(progress, total)
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Batch Processing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows progress of batch operations"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(progress: Int, total: Int): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Processing images")
            .setContentText(if (total > 0) "$progress of $total" else "Starting...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        if (total > 0) {
            builder.setProgress(total, progress, false)
        } else {
            builder.setProgress(0, 0, true)
        }
        return builder.build()
    }

    private fun updateNotification(progress: Int, total: Int) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(progress, total))
    }
}
