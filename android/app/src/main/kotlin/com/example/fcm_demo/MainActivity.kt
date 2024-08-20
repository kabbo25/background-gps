package com.example.fcm_demo

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fcm_demo/locationService"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startLocationService()
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopLocationService()
                    result.success(null)
                }
                "sendBroadcast" -> {
                    val action = call.argument<String>("action")
                    if (action != null) {
                        sendBroadcastAction(action)
                        result.success(null)
                    } else {
                        result.error("INVALID_ACTION", "Action is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun sendBroadcastAction(action: String) {
        val intent = Intent(this, ServiceReceiver::class.java).apply {
            this.action = action
        }
        sendBroadcast(intent)
    }

    private fun startLocationService() {
        val intent = Intent(this, LocationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopLocationService() {
        val intent = Intent(this, LocationService::class.java)
        stopService(intent)
    }
}
