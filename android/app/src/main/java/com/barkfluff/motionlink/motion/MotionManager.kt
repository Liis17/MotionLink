package com.barkfluff.motionlink.motion

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import com.barkfluff.motionlink.model.MotionSnapshot
import com.barkfluff.motionlink.model.Vector3
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MotionManager(context: Context) : SensorEventListener {

    private val appContext = context.applicationContext
    private val sensorManager =
        appContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val rotationVectorSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val linearAccelSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
    private val gravitySensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY)
    private val gyroSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

    private val rotationMatrix = FloatArray(9)
    private val orientation = FloatArray(3)

    @Volatile private var lastRotV: FloatArray? = null
    @Volatile private var lastLinearAccel = floatArrayOf(0f, 0f, 0f)
    @Volatile private var lastGravity = floatArrayOf(0f, 0f, 0f)
    @Volatile private var lastGyro = floatArrayOf(0f, 0f, 0f)

    private val _latest = MutableStateFlow<MotionSnapshot?>(null)
    val latest: StateFlow<MotionSnapshot?> = _latest.asStateFlow()

    private var scope: CoroutineScope? = null
    private var tickerJob: Job? = null
    private var onUpdate: ((MotionSnapshot) -> Unit)? = null

    /**
     * Запускает чтение сенсоров и тикер 30 Гц. onUpdate вызывается из background-потока.
     */
    fun start(onUpdate: ((MotionSnapshot) -> Unit)? = null) {
        if (scope != null) return
        this.onUpdate = onUpdate

        // SENSOR_DELAY_GAME ≈ 50 Гц, достаточно для 30 Гц-тикера.
        rotationVectorSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
        linearAccelSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
        gravitySensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
        gyroSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }

        val s = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        scope = s
        tickerJob = s.launch {
            while (true) {
                buildSnapshot()?.let { snap ->
                    _latest.value = snap
                    this@MotionManager.onUpdate?.invoke(snap)
                }
                delay(TICK_INTERVAL_MS)
            }
        }
    }

    fun stop() {
        tickerJob?.cancel(); tickerJob = null
        scope?.cancel(); scope = null
        sensorManager.unregisterListener(this)
        onUpdate = null
        _latest.value = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR ->
                lastRotV = event.values.copyOf(maxOf(event.values.size, 4))
            Sensor.TYPE_LINEAR_ACCELERATION -> lastLinearAccel = event.values.copyOf()
            Sensor.TYPE_GRAVITY -> lastGravity = event.values.copyOf()
            Sensor.TYPE_GYROSCOPE -> lastGyro = event.values.copyOf()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun buildSnapshot(): MotionSnapshot? {
        val rotV = lastRotV ?: return null
        SensorManager.getRotationMatrixFromVector(rotationMatrix, rotV)
        SensorManager.getOrientation(rotationMatrix, orientation)

        val yawDeg = Math.toDegrees(orientation[0].toDouble())
        val pitchDeg = Math.toDegrees(orientation[1].toDouble())
        val rollDeg = Math.toDegrees(orientation[2].toDouble())

        val accel = lastLinearAccel
        val grav = lastGravity
        val gyro = lastGyro

        return MotionSnapshot(
            t = System.currentTimeMillis() / 1000.0,
            roll = rollDeg,
            pitch = pitchDeg,
            yaw = yawDeg,
            acceleration = Vector3(
                (accel[0] / G).toDouble(),
                (accel[1] / G).toDouble(),
                (accel[2] / G).toDouble(),
            ),
            gravity = Vector3(
                (grav[0] / G).toDouble(),
                (grav[1] / G).toDouble(),
                (grav[2] / G).toDouble(),
            ),
            rotationRate = Vector3(
                gyro[0].toDouble(),
                gyro[1].toDouble(),
                gyro[2].toDouble(),
            ),
        )
    }

    companion object {
        private const val G = 9.80665f
        private const val TICK_INTERVAL_MS = 33L // ~30 Гц
    }
}
