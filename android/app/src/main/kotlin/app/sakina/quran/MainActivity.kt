package app.sakina.quran

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
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
                else -> result.notImplemented()
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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
