package app.sakina.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/** A quiet-window edge or a Fajr wake is due. */
class AlarmEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == AlarmPlanner.ACTION_WAKE) {
            val now = System.currentTimeMillis()
            val alarm = AlarmStore.dueWake(context, now)
            if (alarm != null) {
                AlarmStore.setSnooze(context, null)
                val start = Intent(context, FajrWakeService::class.java)
                    .setAction(FajrWakeService.ACTION_START)
                    .putExtra(FajrWakeService.EXTRA_ALARM, alarm.toString())
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(start)
                    } else {
                        context.startService(start)
                    }
                } catch (e: Exception) {
                    Log.e("SakinaAlarms", "Fajr wake could not start", e)
                }
            }
        }
        AlarmPlanner.rearm(context)
    }
}

/** System alarms are lost on reboot and app update; arm them again. */
class AlarmRearmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AlarmPlanner.rearm(context)
    }
}
