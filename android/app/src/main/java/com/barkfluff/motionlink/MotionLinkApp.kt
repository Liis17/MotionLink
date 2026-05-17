package com.barkfluff.motionlink

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.barkfluff.motionlink.discovery.DiscoveryService
import com.barkfluff.motionlink.model.AppState
import com.barkfluff.motionlink.model.DiscoveredServer
import com.barkfluff.motionlink.motion.MotionManager
import com.barkfluff.motionlink.motion.MotionSender
import com.barkfluff.motionlink.ui.DiscoveryScreen
import com.barkfluff.motionlink.ui.MotionHUDScreen
import com.barkfluff.motionlink.ui.MotionLinkTheme

@Composable
fun MotionLinkApp() {
    val context = LocalContext.current.applicationContext

    val discovery = remember { DiscoveryService(context) }
    val motion = remember { MotionManager(context) }
    val sender = remember { MotionSender() }

    var state by remember { mutableStateOf<AppState>(AppState.Searching) }

    val servers by discovery.servers.collectAsStateWithLifecycle()
    val snapshot by motion.latest.collectAsStateWithLifecycle()
    val senderState by sender.state.collectAsStateWithLifecycle()

    DisposableEffect(state) {
        val active = state
        when (active) {
            AppState.Searching -> {
                discovery.start()
            }
            is AppState.Streaming -> {
                discovery.stop()
                sender.start(active.server)
                motion.start { snap -> sender.send(snap) }
            }
        }
        onDispose {
            when (active) {
                AppState.Searching -> discovery.stop()
                is AppState.Streaming -> {
                    motion.stop()
                    sender.stop()
                }
            }
        }
    }

    MotionLinkTheme {
        AnimatedContent(
            targetState = state,
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            label = "screen",
        ) { s ->
            when (s) {
                AppState.Searching -> DiscoveryScreen(
                    servers = servers,
                    onConnect = { server: DiscoveredServer ->
                        state = AppState.Streaming(server)
                    },
                )
                is AppState.Streaming -> MotionHUDScreen(
                    server = s.server,
                    snapshot = snapshot,
                    senderState = senderState,
                    onDisconnect = { state = AppState.Searching },
                )
            }
        }
    }
}
