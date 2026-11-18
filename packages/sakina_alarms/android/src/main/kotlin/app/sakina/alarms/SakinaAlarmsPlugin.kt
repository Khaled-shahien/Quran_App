package app.sakina.alarms

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Registered in every Flutter engine, so the background rescheduler can
 * update the alarms as well as the app.
 */
class SakinaAlarmsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "sakina/alarms").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        when (call.method) {
            "setQuietWindows" -> {
                val day = call.argument<String>("day") ?: return result.error("args", "day", null)
                val windows = JSONArray()
                for (w in call.argument<List<List<Number>>>("windows") ?: emptyList()) {
                    windows.put(JSONArray(listOf(w[0].toLong(), w[1].toLong())))
                }
                AlarmStore.putQuiet(context, day, windows)
                AlarmPlanner.rearm(context)
                result.success(null)
            }
            "setFajrWake" -> {
                val day = call.argument<String>("day") ?: return result.error("args", "day", null)
                val alarm = call.argument<Map<String, Any?>>("alarm")?.let { JSONObject(it) }
                AlarmStore.putWake(context, day, alarm)
                AlarmPlanner.rearm(context)
                result.success(null)
            }
            "clearAll" -> {
                AlarmStore.clear(context)
                AlarmPlanner.rearm(context)
                result.success(null)
            }
            "hasDndAccess" -> result.success(nm.isNotificationPolicyAccessGranted)
            "openDndAccessSettings" -> {
                open(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                result.success(null)
            }
            "canUseFullScreenIntent" -> result.success(
                if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true,
            )
            "openFullScreenIntentSettings" -> {
                if (Build.VERSION.SDK_INT >= 34) {
                    open(
                        Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                            .setData(Uri.parse("package:${context.packageName}")),
                    )
                } else {
                    open(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),
                    )
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun open(intent: Intent) {
        try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            context.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.parse("package:${context.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }
}
