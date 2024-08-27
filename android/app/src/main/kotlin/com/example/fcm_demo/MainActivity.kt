package com.example.fcm_demo

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fcm_demo/locationService"
    private val LOCATION_PERMISSION_REQUEST_CODE = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    if (checkAndRequestPermissions()) {
                        startLocationService()
                        result.success(null)
                    } else {
                        result.error("PERMISSION_DENIED", "Location permission is required", null)
                    }
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestPermissions()
    }

    private fun checkAndRequestPermissions(): Boolean {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            Manifest.permission.POST_NOTIFICATIONS
        )

        val permissionsToRequest = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), LOCATION_PERMISSION_REQUEST_CODE)
            return false
        }
        return true
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                // All permissions granted, you can start your service here if needed
                startLocationService()
            } else {
                // Handle the case where permissions are not granted
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