package app.sakina.quran

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity (a FlutterActivity) shares the engine with the
// background recitation service.
class MainActivity : AudioServiceActivity() {
    private var qiblaCompass: QiblaCompass? = null
    private var qiblaChannel: EventChannel? = null
    private var permissionsChannel: MethodChannel? = null
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        qiblaCompass = QiblaCompass(this)
        qiblaChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "sakina/qibla_heading")
        qiblaChannel?.setStreamHandler(qiblaCompass)
        permissionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sakina/permissions")
        permissionsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // False after a permanent refusal: the system will no longer
                // show its dialog, so only Settings can allow notifications.
                "shouldShowNotificationRationale" -> result.success(
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
                )
                "openNotificationSettings" -> result.success(openNotificationSettings())
                // Read-only; the app never asks to be exempted directly.
                "isIgnoringBatteryOptimizations" -> result.success(
                    (getSystemService(POWER_SERVICE) as PowerManager)
                        .isIgnoringBatteryOptimizations(packageName)
                )
                "openBatteryOptimizationSettings" -> result.success(openBatteryOptimizationSettings())
                else -> result.notImplemented()
            }
        }
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sakina/widget")
        widgetChannel?.setMethodCallHandler { call, result ->
            if (call.method == "update") {
                PrayerTimesWidget.updateAll(applicationContext)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
        }
        return try {
            startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openBatteryOptimizationSettings(): Boolean = try {
        startActivity(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        true
    } catch (_: Exception) {
        openNotificationSettings()
    }

    override fun onPause() {
        qiblaCompass?.stop()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        qiblaCompass?.resume()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        qiblaCompass?.onCancel(null)
        qiblaChannel?.setStreamHandler(null)
        qiblaChannel = null
        qiblaCompass = null
        permissionsChannel?.setMethodCallHandler(null)
        permissionsChannel = null
        widgetChannel?.setMethodCallHandler(null)
        widgetChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
