package app.sakina.alarms

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Keeps exactly one system alarm per feature armed: the next quiet-window
 * edge and the next Fajr wake. Each alarm re-arms the following one.
 */
internal object AlarmPlanner {
    private const val TAG = "SakinaAlarms"
    const val ACTION_QUIET = "app.sakina.alarms.QUIET"
    const val ACTION_WAKE = "app.sakina.alarms.WAKE"
    private const val REQUEST_QUIET = 7101
    private const val REQUEST_WAKE = 7102

    fun rearm(c: Context) {
        val now = System.currentTimeMillis()
        QuietMode.sync(c, now)
        val nextEdge = AlarmStore.quietWindows(c)
            .flatMap { listOf(it[0], it[1]) }
            .filter { it > now }
            .minOrNull()
        arm(c, REQUEST_QUIET, ACTION_QUIET, nextEdge, alarmClock = false)
        arm(c, REQUEST_WAKE, ACTION_WAKE, AlarmStore.nextWake(c, now)?.optLong("at"), alarmClock = true)
    }

    private fun arm(c: Context, request: Int, action: String, at: Long?, alarmClock: Boolean) {
        val am = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            c,
            request,
            Intent(c, AlarmEventReceiver::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        if (at == null) {
            am.cancel(pi)
            return
        }
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
        try {
            when {
                alarmClock && exact -> am.setAlarmClock(AlarmManager.AlarmClockInfo(at, openApp(c)), pi)
                exact -> am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                else -> am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact alarm refused; using an inexact one", e)
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        }
    }

    private fun openApp(c: Context): PendingIntent? {
        val launch = c.packageManager.getLaunchIntentForPackage(c.packageName) ?: return null
        return PendingIntent.getActivity(c, REQUEST_WAKE, launch, PendingIntent.FLAG_IMMUTABLE)
    }
}

/**
 * Do Not Disturb during the quiet windows. It is turned on only when the
 * phone is in normal mode and turned off only if this app turned it on and
 * the user has not changed it since.
 */
internal object QuietMode {
    private fun manager(c: Context) =
        c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun hasAccess(c: Context) = manager(c).isNotificationPolicyAccessGranted

    fun sync(c: Context, now: Long) {
        val nm = manager(c)
        val active = AlarmStore.quietWindows(c).any { now >= it[0] && now < it[1] }
        val ours = AlarmStore.quietOn(c)
        if (!nm.isNotificationPolicyAccessGranted) {
            if (!active && ours) AlarmStore.setQuietOn(c, false)
            return
        }
        if (active && !ours) {
            if (nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALL) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                AlarmStore.setQuietOn(c, true)
            }
        } else if (!active && ours) {
            if (nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_PRIORITY) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
            }
            AlarmStore.setQuietOn(c, false)
        }
    }
}
