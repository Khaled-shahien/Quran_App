package com.example.sakina_app

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// AudioServiceActivity (a FlutterActivity) shares the engine with the
// background recitation service.
class MainActivity : AudioServiceActivity() {
    private var qiblaCompass: QiblaCompass? = null
    private var qiblaChannel: EventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        qiblaCompass = QiblaCompass(this)
        qiblaChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "sakina/qibla_heading")
        qiblaChannel?.setStreamHandler(qiblaCompass)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
