package app.sakina.quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Home-screen widget: the day's five prayers with the next one marked, the
 * place and the Hijri date. It reads what the app saved under
 * `flutter.prayer_widget_v1` in its own SharedPreferences and picks the
 * next prayer from the current time, so it stays right between updates
 * (the system redraws it every 30 minutes, and the app on every change).
 */
class PrayerTimesWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val PREFS = "FlutterSharedPreferences"
        private const val KEY = "flutter.prayer_widget_v1"

        private val nameIds = intArrayOf(
            R.id.prayer_name_0, R.id.prayer_name_1, R.id.prayer_name_2,
            R.id.prayer_name_3, R.id.prayer_name_4,
        )
        private val timeIds = intArrayOf(
            R.id.prayer_time_0, R.id.prayer_time_1, R.id.prayer_time_2,
            R.id.prayer_time_3, R.id.prayer_time_4,
        )
        private val rowIds = intArrayOf(
            R.id.prayer_row_0, R.id.prayer_row_1, R.id.prayer_row_2,
            R.id.prayer_row_3, R.id.prayer_row_4,
        )

        /** Redraws every placed widget (called by the app after a change). */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerTimesWidget::class.java))
            if (ids.isNotEmpty()) {
                val views = build(context)
                for (id in ids) manager.updateAppWidget(id, views)
            }
        }

        private data class Prayer(val name: String, val at: Long, val label: String)

        fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            val open = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            views.setOnClickPendingIntent(
                R.id.prayer_widget_root,
                PendingIntent.getActivity(
                    context, 0, open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )

            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            val prayers = mutableListOf<Prayer>()
            var place = ""
            var hijri = ""
            try {
                if (raw != null) {
                    val json = JSONObject(raw)
                    place = json.optString("place")
                    hijri = json.optString("hijri")
                    val list = json.getJSONArray("prayers")
                    for (i in 0 until list.length()) {
                        val p = list.getJSONObject(i)
                        prayers.add(Prayer(p.getString("name"), p.getLong("at"), p.getString("label")))
                    }
                }
            } catch (_: Exception) {
                prayers.clear()
            }

            val now = System.currentTimeMillis()
            val nextIndex = prayers.indexOfFirst { it.at > now }
            if (prayers.size < 5 || nextIndex < 0) {
                views.setViewVisibility(R.id.prayer_list, View.GONE)
                views.setViewVisibility(R.id.prayer_empty, View.VISIBLE)
                views.setTextViewText(R.id.prayer_place, place)
                views.setTextViewText(R.id.prayer_hijri, hijri)
                return views
            }
            // The five prayers of the day the next prayer belongs to.
            val start = (nextIndex / 5) * 5
            val day = prayers.subList(start, minOf(start + 5, prayers.size))
            views.setViewVisibility(R.id.prayer_list, View.VISIBLE)
            views.setViewVisibility(R.id.prayer_empty, View.GONE)
            views.setTextViewText(R.id.prayer_place, place)
            views.setTextViewText(R.id.prayer_hijri, hijri)
            for (i in 0 until 5) {
                val p = day.getOrNull(i)
                views.setTextViewText(nameIds[i], p?.name ?: "")
                views.setTextViewText(timeIds[i], p?.label ?: "")
                val isNext = start + i == nextIndex
                views.setInt(
                    rowIds[i], "setBackgroundResource",
                    if (isNext) R.drawable.prayer_widget_next else android.R.color.transparent,
                )
            }
            return views
        }
    }
}
