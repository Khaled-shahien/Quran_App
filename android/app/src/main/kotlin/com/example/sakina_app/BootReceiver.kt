package com.example.sakina_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import java.util.concurrent.TimeUnit

/**
 * Boot Receiver - Handles device boot and app updates
 * 
 * This receiver listens for:
 * - BOOT_COMPLETED: Device has finished booting
 * - QUICKBOOT_POWERON: Fast boot (some devices)
 * - MY_PACKAGE_REPLACED: App was updated
 * 
 * When triggered, it initializes WorkManager to reschedule all alarms
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        private const val UNIQUE_WORK_NAME = "reschedule_alarms_boot_task"
        private const val DART_TASK_KEY = "be.tramckrijte.workmanager.DART_TASK"
        private const val PAYLOAD_KEY = "be.tramckrijte.workmanager.INPUT_DATA"
        private const val IS_IN_DEBUG_MODE_KEY = "be.tramckrijte.workmanager.IS_IN_DEBUG_MODE_KEY"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.i(TAG, "Device boot completed - rescheduling alarms")
                handleBootCompleted(context)
            }
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.i(TAG, "Quick boot detected - rescheduling alarms")
                handleBootCompleted(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.i(TAG, "Package replaced - rescheduling alarms")
                handleBootCompleted(context)
            }
        }
    }
    
    /**
     * Handle boot completed event
     * This schedules a WorkManager task to reschedule all alarms
     */
    private fun handleBootCompleted(context: Context) {
        try {
            val inputData = Data.Builder()
                .putString(DART_TASK_KEY, "reschedule_alarms")
                .putString(PAYLOAD_KEY, "{\"source\":\"boot_receiver\"}")
                .putBoolean(IS_IN_DEBUG_MODE_KEY, false)
                .build()

            val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
                .setInputData(inputData)
                .setInitialDelay(15, TimeUnit.SECONDS)
                .addTag("quran_alarm_reschedule")
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                request
            )

            Log.i(TAG, "Boot reschedule work enqueued")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling boot: ${e.message}", e)
        }
    }
}
