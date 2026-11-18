package app.sakina.alarms

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * What the app asked for, kept natively so boot and each alarm can re-arm
 * the next one without the Flutter engine.
 *
 * quiet: {day: [[startMs, endMs], ...]}; wake: {day: alarm}; snooze: alarm.
 * Times are absolute (epoch ms), so a time zone change does not move them.
 */
internal object AlarmStore {
    private const val PREFS = "sakina_alarms"
    private const val QUIET = "quiet"
    private const val WAKE = "wake"
    private const val SNOOZE = "snooze"
    private const val QUIET_ON = "quiet_on"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(c: Context, key: String): JSONObject = try {
        JSONObject(prefs(c).getString(key, null) ?: "{}")
    } catch (e: Exception) {
        JSONObject()
    }

    private fun write(c: Context, key: String, value: JSONObject) {
        prefs(c).edit().putString(key, value.toString()).apply()
    }

    fun putQuiet(c: Context, day: String, windows: JSONArray) {
        val all = read(c, QUIET)
        if (windows.length() == 0) all.remove(day) else all.put(day, windows)
        val now = System.currentTimeMillis()
        for (key in all.keys().asSequence().toList()) {
            val list = all.optJSONArray(key) ?: continue
            if ((0 until list.length()).all { list.getJSONArray(it).getLong(1) < now }) all.remove(key)
        }
        write(c, QUIET, all)
    }

    fun quietWindows(c: Context): List<LongArray> {
        val all = read(c, QUIET)
        val out = mutableListOf<LongArray>()
        for (key in all.keys()) {
            val list = all.optJSONArray(key) ?: continue
            for (i in 0 until list.length()) {
                val w = list.optJSONArray(i) ?: continue
                out.add(longArrayOf(w.getLong(0), w.getLong(1)))
            }
        }
        return out
    }

    fun putWake(c: Context, day: String, alarm: JSONObject?) {
        val all = read(c, WAKE)
        if (alarm == null) all.remove(day) else all.put(day, alarm)
        val now = System.currentTimeMillis()
        for (key in all.keys().asSequence().toList()) {
            if ((all.optJSONObject(key)?.optLong("sunrise") ?: 0L) < now) all.remove(key)
        }
        write(c, WAKE, all)
    }

    private fun wakeAlarms(c: Context): List<JSONObject> {
        val all = read(c, WAKE)
        val out = all.keys().asSequence().mapNotNull { all.optJSONObject(it) }.toMutableList()
        val snooze = read(c, SNOOZE)
        if (snooze.has("at")) out.add(snooze)
        return out
    }

    /** The next wake alarm (a snooze included) after [now]. */
    fun nextWake(c: Context, now: Long): JSONObject? =
        wakeAlarms(c).filter { it.optLong("at") > now }.minByOrNull { it.optLong("at") }

    /** The alarm that is due at [now]: started within a minute, before sunrise. */
    fun dueWake(c: Context, now: Long): JSONObject? =
        wakeAlarms(c)
            .filter { it.optLong("at") in (now - 120_000)..(now + 60_000) && it.optLong("sunrise") > now }
            .minByOrNull { it.optLong("at") }

    fun setSnooze(c: Context, alarm: JSONObject?) = write(c, SNOOZE, alarm ?: JSONObject())

    fun quietOn(c: Context) = prefs(c).getBoolean(QUIET_ON, false)

    fun setQuietOn(c: Context, on: Boolean) {
        prefs(c).edit().putBoolean(QUIET_ON, on).apply()
    }

    /** Forgets every request; whether quiet mode is ours is kept so it can be ended. */
    fun clear(c: Context) {
        prefs(c).edit().remove(QUIET).remove(WAKE).remove(SNOOZE).apply()
    }
}
