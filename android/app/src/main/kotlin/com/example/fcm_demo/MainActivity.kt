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



//
//
//package com.example.fcm_demo
//
//import android.app.Service
//import android.content.Intent
//import android.os.IBinder
//import com.google.android.gms.location.*
//
//import okhttp3.OkHttpClient
//import okhttp3.Request
//import okhttp3.RequestBody
//import okhttp3.MediaType.Companion.toMediaType
//import okhttp3.RequestBody.Companion.toRequestBody
//import org.json.JSONObject
//import java.io.IOException
//import android.util.Log
//
//class LocationService : Service() {
//    private lateinit var fusedLocationClient: FusedLocationProviderClient
//    private lateinit var locationCallback: LocationCallback
//    private val backendUrl = "http://10.0.3.135:8080/api/location" // Replace with your backend URL
//
//    override fun onCreate() {
//        super.onCreate()
//        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
//        setupLocationRequest()
//    }
//
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        if (intent?.action == "START_LOCATION_SERVICE") {
//            startLocationUpdates()
//        }
//        return START_NOT_STICKY
//    }
//
//    private fun setupLocationRequest() {
//        val locationRequest = LocationRequest.create().apply {
//            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
//        }
//
//        locationCallback = object : LocationCallback() {
//            override fun onLocationResult(locationResult: LocationResult) {
//                val location = locationResult.lastLocation
//                if (location != null) {
//                    // Convert location to JSON
//                    val jsonObject = JSONObject().apply {
//                        put("latitude", location.latitude)
//                        put("longitude", location.longitude)
//                        put("timestamp", location.time)
//                    }
//
//                    // Send the location to the backend
//                    //sendLocationToBackend(jsonObject.toString())
//
//                    //log location
//                    val TAG = "yourLocation";
//                    Log.d("FC", "onLocationResult: " + jsonObject.toString());
//                    android.util.Log.d(TAG, "onLocationResult: " + jsonObject.toString());
//                }
//            }
//        }
//    }
//
//    private fun startLocationUpdates() {
//        try {
//            fusedLocationClient.requestLocationUpdates(
//                LocationRequest.create(),
//                locationCallback,
//                null
//            )
//        } catch (unlikely: SecurityException) {
//            stopSelf() // Stop service if location permission is not granted
//        }
//    }
//
//    private fun sendLocationToBackend(locationData: String) {
//        val client = OkHttpClient()
//
//        val mediaType = "application/json; charset=utf-8".toMediaType()
//        val body: RequestBody = locationData.toRequestBody(mediaType)
//
//        val request = Request.Builder()
//            .url(backendUrl)
//            .post(body)
//            .build()
//
//        client.newCall(request).enqueue(object : okhttp3.Callback {
//            override fun onFailure(call: okhttp3.Call, e: IOException) {
//                e.printStackTrace() // Handle request failure
//                stopSelf() // Stop service on failure
//            }
//
//            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
//                if (response.isSuccessful) {
//                    // Stop the service after successful location send
//                    stopSelf()
//                } else {
//                    // Handle error response and stop service
//                    stopSelf()
//                }
//            }
//        })
//    }
//
//    override fun onBind(intent: Intent?): IBinder? {
//        return null
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        fusedLocationClient.removeLocationUpdates(locationCallback)
//    }
//}
//
////package com.example.fcm_demo
////
////import android.app.Notification
////import android.app.NotificationChannel
////import android.app.NotificationManager
////import android.app.PendingIntent
////import android.app.Service
////import android.content.Context
////import android.content.Intent
////import android.os.Build
////import android.os.IBinder
////import androidx.core.app.NotificationCompat
////import com.google.android.gms.location.FusedLocationProviderClient
////import com.google.android.gms.location.LocationCallback
////import com.google.android.gms.location.LocationRequest
////import com.google.android.gms.location.LocationResult
////import com.google.android.gms.location.LocationServices
////
////class LocationService : Service() {
////    private lateinit var fusedLocationClient: FusedLocationProviderClient
////    private lateinit var locationCallback: LocationCallback
////    private val CHANNEL_ID = "location_service_channel"
////    private val NOTIFICATION_ID = 1
////
////    override fun onCreate() {
////        super.onCreate()
////        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
////        createNotificationChannel()
////        setupLocationUpdates()
////    }
////
////    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
////        // Start the service as a foreground service immediately
////        startForeground(NOTIFICATION_ID, createNotification()) // error causing here due to mAllowStartForeground false: service com.example.fcm_demo/.LocationService
////
////        // Start location updates
////        startLocationUpdates()
////
////        return START_STICKY
////    }
////
////    private fun setupLocationUpdates() {
////        val locationRequest = LocationRequest.create().apply {
////            interval = 10000 // 10 seconds
////            fastestInterval = 5000 // 5 seconds
////            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
////        }
////
////        locationCallback = object : LocationCallback() {
////            override fun onLocationResult(locationResult: LocationResult) {
////                locationResult.locations.forEach { location ->
////                    // Handle location updates here
////                    // For example, you could send this data to your Flutter app
////                }
////            }
////        }
////    }
////
////    private fun startLocationUpdates() {
////        try {
////            fusedLocationClient.requestLocationUpdates(
////                LocationRequest.create(),
////                locationCallback,
////                null
////            )
////        } catch (unlikely: SecurityException) {
////            // Handle the case where location permission is not granted
////        }
////    }
////
////    override fun onBind(intent: Intent?): IBinder? {
////        return null
////    }
////
////    override fun onDestroy() {
////        super.onDestroy()
////        fusedLocationClient.removeLocationUpdates(locationCallback)
////    }
////
////    private fun createNotification(): Notification {
////        val notificationIntent = Intent(this, MainActivity::class.java)
////        val pendingIntent = PendingIntent.getActivity(
////            this, 0, notificationIntent,
////            PendingIntent.FLAG_IMMUTABLE
////        )
////
////        return NotificationCompat.Builder(this, CHANNEL_ID)
////            .setContentTitle("Location Service")
////            .setContentText("Running in the background")
////            .setSmallIcon(R.drawable.ic_notification)
////            .setContentIntent(pendingIntent)
////            .build()
////    }
////
////    private fun createNotificationChannel() {
////        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
////            val name = "Location Service Channel"
////            val descriptionText = "Channel for location service"
////            val importance = NotificationManager.IMPORTANCE_DEFAULT
////            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
////                description = descriptionText
////            }
////            val notificationManager: NotificationManager =
////                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
////            notificationManager.createNotificationChannel(channel)
////        }
////    }
////}