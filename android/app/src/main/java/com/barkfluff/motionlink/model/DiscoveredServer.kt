package com.barkfluff.motionlink.model

data class DiscoveredServer(
    val host: String,
    val port: Int,
    val name: String?,
) {
    val id: String get() = host
}
