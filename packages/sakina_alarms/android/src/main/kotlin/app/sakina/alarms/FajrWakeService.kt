package app.sakina.alarms

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import org.json.JSONObject

/**
 * Plays the Fajr wake alarm: starts quietly and grows louder, shows a
 * full-screen alarm over the lock screen, and stops on Stop, on Snooze, at
 * sunrise, or after 15 minutes at the most.
 */
class FajrWakeService : Service() {
    companion object {
        const val ACTION_START = "app.sakina.alarms.WAKE_START"
        const val ACTION_STOP = "app.sakina.alarms.WAKE_STOP"
        const val ACTION_SNOOZE = "app.sakina.alarms.WAKE_SNOOZE"
        const val EXTRA_ALARM = "alarm"
        private const val CHANNEL_ID = "sakina_fajr_wake"
        private const val NOTIFICATION_ID = 7103
        private const val MAX_RING_MS = 15 * 60_000L
        private const val SNOOZE_MARGIN_MS = 10 * 60_000L

        /** The ringing alarm, read by [FajrWakeActivity]. */
        @Volatile
        var current: JSONObject? = null

        /** Lets the screen close itself when the alarm ends elsewhere. */
        @Volatile
        var onFinished: (() -> Unit)? = null

        /** Snooze is offered only while it still ends well before sunrise. */
        fun canSnooze(alarm: JSONObject, now: Long): Boolean =
            now + alarm.optInt("snoozeMinutes", 5) * 60_000L <= alarm.optLong("sunrise") - SNOOZE_MARGIN_MS
    }

    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var volume = 0.15f

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val raw = intent.getStringExtra(EXTRA_ALARM)
                if (raw == null) finishAlarm() else start(JSONObject(raw))
            }
            ACTION_SNOOZE -> snooze()
            else -> {
                AlarmStore.setSnooze(this, null)
                finishAlarm()
            }
        }
        return START_NOT_STICKY
    }

    private fun start(alarm: JSONObject) {
        current = alarm
        val texts = alarm.optJSONObject("texts") ?: JSONObject()
        val notification = buildNotification(alarm, texts)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "sakina:fajr_wake").apply {
            acquire(MAX_RING_MS)
        }
        play(alarm.optString("sound", ""))
        val stopAt = minOf(alarm.optLong("sunrise"), System.currentTimeMillis() + MAX_RING_MS)
        handler.postDelayed({ finishAlarm() }, maxOf(0L, stopAt - System.currentTimeMillis()))
    }

    private fun play(sound: String) {
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        fun prepare(useRecording: Boolean): MediaPlayer {
            val p = MediaPlayer()
            p.setAudioAttributes(attributes)
            val resId = if (useRecording && sound.isNotEmpty()) {
                resources.getIdentifier(sound, "raw", packageName)
            } else {
                0
            }
            if (resId != 0) {
                resources.openRawResourceFd(resId).use { p.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
            } else {
                val uri = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                p.setDataSource(this, uri)
            }
            p.isLooping = true
            p.setVolume(volume, volume)
            p.prepare()
            return p
        }
        player = try {
            prepare(true)
        } catch (e: Exception) {
            Log.w("SakinaAlarms", "Recording unavailable; using the alarm sound", e)
            try { prepare(false) } catch (e2: Exception) { null }
        }
        player?.start()
        handler.postDelayed(object : Runnable {
            override fun run() {
                val p = player ?: return
                volume = minOf(1f, volume + 0.06f)
                p.setVolume(volume, volume)
                if (volume < 1f) handler.postDelayed(this, 6_000)
            }
        }, 6_000)
    }

    private fun snooze() {
        val alarm = current
        val now = System.currentTimeMillis()
        if (alarm != null && canSnooze(alarm, now)) {
            val again = JSONObject(alarm.toString())
            again.put("at", now + alarm.optInt("snoozeMinutes", 5) * 60_000L)
            AlarmStore.setSnooze(this, again)
        }
        finishAlarm()
        AlarmPlanner.rearm(this)
    }

    private fun finishAlarm() {
        handler.removeCallbacksAndMessages(null)
        player?.let {
            try { it.stop() } catch (_: Exception) {}
            it.release()
        }
        player = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        current = null
        onFinished?.invoke()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        player?.release()
        player = null
        wakeLock?.let { if (it.isHeld) it.release() }
        super.onDestroy()
    }

    private fun buildNotification(alarm: JSONObject, texts: JSONObject): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                texts.optString("channelName", "Fajr"),
                NotificationManager.IMPORTANCE_HIGH,
            )
            // The service plays the sound itself so it can grow louder.
            channel.setSound(null, null)
            channel.enableVibration(true)
            channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            nm.createNotificationChannel(channel)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val screen = PendingIntent.getActivity(
            this, 7104,
            Intent(this, FajrWakeActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            flags,
        )
        fun serviceIntent(action: String, code: Int) = PendingIntent.getService(
            this, code, Intent(this, FajrWakeService::class.java).setAction(action), flags,
        )
        val iconId = resources.getIdentifier("ic_notification", "drawable", packageName)
            .takeIf { it != 0 } ?: applicationInfo.icon
        val icon = Icon.createWithResource(this, iconId)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_MAX)
        }
        builder
            .setSmallIcon(icon)
            .setContentTitle(texts.optString("title"))
            .setContentText(texts.optString("body"))
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setContentIntent(screen)
            .setFullScreenIntent(screen, true)
            .addAction(Notification.Action.Builder(icon, texts.optString("stop"), serviceIntent(ACTION_STOP, 7105)).build())
        if (canSnooze(alarm, System.currentTimeMillis())) {
            builder.addAction(
                Notification.Action.Builder(icon, texts.optString("snooze"), serviceIntent(ACTION_SNOOZE, 7106)).build(),
            )
        }
        return builder.build()
    }
}
