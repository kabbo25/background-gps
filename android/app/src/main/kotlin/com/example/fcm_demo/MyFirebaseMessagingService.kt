package com.example.fcm_demo

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.OneTimeWorkRequest
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import androidx.work.Data

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "Message received from: ${remoteMessage.from}")

        // Schedule work to handle the message
        val work = OneTimeWorkRequest.Builder(LocationWorker::class.java).build()
        WorkManager.getInstance(this).enqueue(work)
    }
}

//class LocationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
//
//    override fun doWork(): Result {
//        val intent = Intent(applicationContext, LocationService::class.java)
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            applicationContext.startForegroundService(intent)
//        } else {
//            applicationContext.startService(intent)
//        }
//        return Result.success()
//    }
//}
class LocationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    override fun doWork(): Result {
        if (ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_FINE_LOCATION)
            == PackageManager.PERMISSION_GRANTED) {
            val intent = Intent(applicationContext, LocationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
            return Result.success()
        }
        return Result.failure()
    }
}
