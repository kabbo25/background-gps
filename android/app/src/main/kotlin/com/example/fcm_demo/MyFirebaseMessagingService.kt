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
import android.app.PendingIntent
import androidx.core.app.JobIntentService

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "Message received from: ${remoteMessage.from}")

        // Schedule work to handle the message
        val work = OneTimeWorkRequest.Builder(LocationWorker::class.java).build()
        WorkManager.getInstance(this).enqueue(work)
    }
}

class LocationWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    override fun doWork(): Result {
        val intent = Intent(applicationContext, LocationService::class.java)
        intent.action = "START_LOCATION_SERVICE"
        // Start the LocationService as a foreground service
        ContextCompat.startForegroundService(applicationContext, intent)

        return Result.success()
//        val pendingIntent = PendingIntent.getService(
//            applicationContext,
//            0,
//            intent,
//            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//        )
//
//        try {
//            pendingIntent.send()
//            return Result.success()
//        } catch (e: PendingIntent.CanceledException) {
//            return Result.failure()
//        }
    }
}
