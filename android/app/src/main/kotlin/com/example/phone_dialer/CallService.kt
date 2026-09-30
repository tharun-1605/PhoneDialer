package com.example.phone_dialer

import android.telecom.Call
import android.telecom.InCallService
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

class CallService : InCallService() {
    
    private val CHANNEL_ID = "incoming_call_channel"
    private val NOTIFICATION_ID = 12345

    companion object {
        var currentCall: Call? = null
        var instance: CallService? = null
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            val number = call.details?.handle?.schemeSpecificPart ?: "Unknown"
            val name = ContactUtils.getContactName(this@CallService, number) ?: number
            val isIncoming = state == Call.STATE_RINGING
            val event = mapOf("number" to number, "name" to name, "isIncoming" to isIncoming, "state" to state)
            
            // Send on UI thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                MainActivity.callEventSink?.success(event)
            }
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        currentCall = call
        instance = this
        call.registerCallback(callCallback)
        
        val number = call.details?.handle?.schemeSpecificPart ?: "Unknown"
        val name = ContactUtils.getContactName(this, number) ?: number
        val isIncoming = call.state == Call.STATE_RINGING
        
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            MainActivity.callEventSink?.success(mapOf("number" to number, "name" to name, "isIncoming" to isIncoming, "state" to call.state, "initial" to true))
        }

        if (isIncoming) {
            if (!MainActivity.isAppInForeground) {
                showIncomingCallNotification(name)
            }
        } else {
            // Outgoing call, just open UI
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)

        if (currentCall == call) {
            currentCall = null
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                MainActivity.callEventSink?.success(mapOf("state" to Call.STATE_DISCONNECTED))
            }
        }
    }

    private fun showIncomingCallNotification(number: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "full_screen")
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val fullScreenIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)

        val answerIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "answered")
        }
        val answerPendingIntent = PendingIntent.getActivity(this, 1, answerIntent, pendingIntentFlags)

        val declineIntent = Intent(this, CallActionReceiver::class.java).apply {
            action = "DECLINE_CALL"
        }
        val declinePendingIntent = PendingIntent.getBroadcast(this, 2, declineIntent, pendingIntentFlags)

        createNotificationChannel()

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_dialer)
            .setContentTitle(number)
            .setContentText("Incoming Call")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(fullScreenIntent, true)
            .setContentIntent(fullScreenIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePendingIntent)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Incoming Calls"
            val descriptionText = "Notifications for incoming calls"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setSound(null, null) // Let the telecom system handle ringing
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
