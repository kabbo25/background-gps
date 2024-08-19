package com.example.fcm_demo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.location.Location
import android.location.LocationManager
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourapp/location"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getLocation") {
                getLocation(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getLocation(result: MethodChannel.Result) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION)
            == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            val location: Location? = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            if (location != null) {
                val latitude = location.latitude
                val longitude = location.longitude

                // Send location back to Flutter
                channel.invokeMethod(
                    "updateLocation",
                    mapOf("latitude" to latitude, "longitude" to longitude)
                )

                result.success("Location obtained")
            } else {
                result.error("UNAVAILABLE", "Location not available.", null)
            }
        } else {
            result.error("PERMISSION_DENIED", "Location permission not granted.", null)
        }
    }
}