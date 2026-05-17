package com.barkfluff.motionlink.model

import org.json.JSONObject

data class Vector3(val x: Double, val y: Double, val z: Double) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("x", x)
        put("y", y)
        put("z", z)
    }
}

data class MotionSnapshot(
    val t: Double,
    val roll: Double,
    val pitch: Double,
    val yaw: Double,
    val acceleration: Vector3,
    val gravity: Vector3,
    val rotationRate: Vector3,
) {
    fun toJsonBytes(): ByteArray = JSONObject().apply {
        put("t", t)
        put("roll", roll)
        put("pitch", pitch)
        put("yaw", yaw)
        put("acceleration", acceleration.toJson())
        put("gravity", gravity.toJson())
        put("rotationRate", rotationRate.toJson())
    }.toString().toByteArray(Charsets.UTF_8)
}
