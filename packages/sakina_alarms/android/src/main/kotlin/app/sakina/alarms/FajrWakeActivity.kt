package app.sakina.alarms

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject

/** The full-screen Fajr alarm: time left until sunrise, Stop and Snooze. */
class FajrWakeActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var untilView: TextView
    private lateinit var snoozeButton: Button
    private var alarm: JSONObject? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val ringing = FajrWakeService.current
        if (ringing == null) {
            finish()
            return
        }
        alarm = ringing
        val texts = ringing.optJSONObject("texts") ?: JSONObject()
        val cream = Color.parseColor("#F4E6C8")

        fun text(value: String, sp: Float, bold: Boolean = false) = TextView(this).apply {
            this.text = value
            setTextColor(cream)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
            gravity = Gravity.CENTER
            if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, dp(8), 0, dp(8))
        }

        fun button(label: String, filled: Boolean, onTap: () -> Unit) = Button(this).apply {
            text = label
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTextColor(if (filled) Color.parseColor("#0D3B3B") else cream)
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                if (filled) setColor(cream) else setStroke(dp(2), cream)
            }
            minHeight = dp(64)
            setOnClickListener { onTap() }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(16) }
        }

        untilView = text("", 20f)
        snoozeButton = button(texts.optString("snooze"), filled = false) { send(FajrWakeService.ACTION_SNOOZE) }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutDirection = View.LAYOUT_DIRECTION_RTL
            setBackgroundColor(Color.parseColor("#0D3B3B"))
            setPadding(dp(32), dp(48), dp(32), dp(48))
            addView(text(texts.optString("title"), 30f, bold = true))
            addView(text(texts.optString("body"), 18f))
            addView(untilView)
            addView(button(texts.optString("stop"), filled = true) { send(FajrWakeService.ACTION_STOP) })
            addView(snoozeButton)
        }
        setContentView(root)
        FajrWakeService.onFinished = { runOnUiThread { finish() } }
        tick()
    }

    private fun tick() {
        val a = alarm ?: return
        val texts = a.optJSONObject("texts") ?: JSONObject()
        val now = System.currentTimeMillis()
        val minutes = ((a.optLong("sunrise") - now + 59_999) / 60_000).toInt()
        untilView.text = if (minutes <= 0) {
            texts.optString("sunriseReached")
        } else {
            texts.optString("untilSunrise").replace("%s", digits("$minutes", texts.optBoolean("arabicDigits", true)))
        }
        snoozeButton.visibility = if (FajrWakeService.canSnooze(a, now)) View.VISIBLE else View.GONE
        handler.postDelayed({ tick() }, 30_000)
    }

    private fun send(action: String) {
        startService(Intent(this, FajrWakeService::class.java).setAction(action))
        finish()
    }

    private fun digits(value: String, arabic: Boolean): String =
        if (!arabic) value else value.map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        FajrWakeService.onFinished = null
        super.onDestroy()
    }
}
