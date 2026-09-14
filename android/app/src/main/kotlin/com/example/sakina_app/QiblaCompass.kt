package com.example.sakina_app

import android.app.Activity
import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.plugin.common.EventChannel

/** Only listens while the Qibla screen subscribes; no location tracking here. */
class QiblaCompass(private val activity: Activity) : EventChannel.StreamHandler, SensorEventListener {
    private val manager = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotation = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private var sink: EventChannel.EventSink? = null
    private var declination = 0f
    private var accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private var gravity: FloatArray? = null
    private var magnetic: FloatArray? = null
    private var lastEmission = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stop()
        sink = events
        val args = arguments as? Map<*, *>
        val lat = (args?.get("latitude") as? Number)?.toFloat()
        val lon = (args?.get("longitude") as? Number)?.toFloat()
        if (lat == null || lon == null) {
            events.error("LOCATION_REQUIRED", "Location is required for true north", null)
            return
        }
        declination = GeomagneticField(lat, lon,
            (args?.get("altitude") as? Number)?.toFloat() ?: 0f,
            System.currentTimeMillis()).declination
        accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
        gravity = null
        magnetic = null
        resume()
    }

    fun resume() {
        if (sink == null) return
        val registered = if (rotation != null) {
            manager.registerListener(this, rotation, SensorManager.SENSOR_DELAY_UI)
        } else if (accelerometer != null && magnetometer != null) {
            val a = manager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
            val m = manager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI)
            a && m
        } else false
        if (!registered) {
            stop()
            sink?.error("SENSOR_UNAVAILABLE", "Compass sensor unavailable", null)
        }
    }

    fun stop() = manager.unregisterListener(this)

    override fun onCancel(arguments: Any?) {
        stop()
        sink = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, value: Int) {
        if (sensor?.type == Sensor.TYPE_ROTATION_VECTOR || sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
            accuracy = value
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val matrix = FloatArray(9)
        if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            SensorManager.getRotationMatrixFromVector(matrix, event.values)
            accuracy = event.accuracy
        } else {
            if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) gravity = event.values.clone()
            if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD) {
                magnetic = event.values.clone()
                accuracy = event.accuracy
            }
            val g = gravity ?: return
            val m = magnetic ?: return
            if (!SensorManager.getRotationMatrix(matrix, null, g, m)) return
        }
        // Avoid rebuilding Flutter at the raw sensor sample rate.
        if (event.timestamp - lastEmission < 100_000_000L) return
        lastEmission = event.timestamp
        @Suppress("DEPRECATION")
        val screenRotation = activity.windowManager.defaultDisplay.rotation
        val axes = when (screenRotation) {
            Surface.ROTATION_90 -> Pair(SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X)
            Surface.ROTATION_180 -> Pair(SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y)
            Surface.ROTATION_270 -> Pair(SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X)
            else -> Pair(SensorManager.AXIS_X, SensorManager.AXIS_Y)
        }
        val remapped = FloatArray(9)
        SensorManager.remapCoordinateSystem(matrix, axes.first, axes.second, remapped)
        val orientation = SensorManager.getOrientation(remapped, FloatArray(3))
        val heading = (Math.toDegrees(orientation[0].toDouble()) + declination + 360) % 360
        sink?.success(mapOf("heading" to heading,
            "needsCalibration" to (accuracy < SensorManager.SENSOR_STATUS_ACCURACY_HIGH)))
    }
}
