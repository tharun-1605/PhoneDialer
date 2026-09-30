package com.example.phone_dialer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "ANSWER_CALL" -> {
                CallService.currentCall?.answer(0)
                // Open the app to show the call screen
                val appIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("action", "answered")
                }
                context.startActivity(appIntent)
            }
            "DECLINE_CALL" -> {
                CallService.currentCall?.reject(false, null)
            }
        }
    }
}
