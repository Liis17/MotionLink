package com.barkfluff.motionlink.model

sealed interface AppState {
    data object Searching : AppState
    data class Streaming(val server: DiscoveredServer) : AppState
}
