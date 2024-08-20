package com.example.fcm_demo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build // <-- Add this import
import android.widget.Toast

class ServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "START_FOREGROUND_SERVICE") {
            Intent(context, LocationService::class.java).also {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(it)
                } else {
                    context.startService(it)
                }
            }
        } else if (intent.action == "STOP_FOREGROUND_SERVICE") {
            Intent(context, LocationService::class.java).also {
                context.stopService(it)
            }
        }
    }
}
