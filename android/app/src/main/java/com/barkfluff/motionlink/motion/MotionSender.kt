package com.barkfluff.motionlink.motion

import android.util.Log
import com.barkfluff.motionlink.model.DiscoveredServer
import com.barkfluff.motionlink.model.MotionSnapshot
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketException

class MotionSender {

    enum class State { Idle, Ready, Failed }

    private val _state = MutableStateFlow(State.Idle)
    val state: StateFlow<State> = _state.asStateFlow()

    private var socket: DatagramSocket? = null
    private var target: InetAddress? = null
    private var port: Int = 0

    private var scope: CoroutineScope? = null
    private var senderJob: Job? = null
    private val queue = Channel<MotionSnapshot>(capacity = Channel.CONFLATED)

    fun start(server: DiscoveredServer) {
        if (scope != null) return
        try {
            socket = DatagramSocket()
            target = InetAddress.getByName(server.host)
            port = server.port
            _state.value = State.Ready
        } catch (e: Exception) {
            Log.w(TAG, "init failed: ${e.message}")
            _state.value = State.Failed
            stop()
            return
        }

        val s = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        scope = s
        senderJob = s.launch {
            for (snap in queue) {
                val sock = socket ?: break
                val addr = target ?: break
                try {
                    val bytes = snap.toJsonBytes()
                    sock.send(DatagramPacket(bytes, bytes.size, addr, port))
                } catch (_: SocketException) {
                    return@launch
                } catch (e: Exception) {
                    Log.w(TAG, "send failed: ${e.message}")
                }
            }
        }
    }

    fun send(snapshot: MotionSnapshot) {
        queue.trySend(snapshot)
    }

    fun stop() {
        senderJob?.cancel(); senderJob = null
        scope = null
        runCatching { socket?.close() }
        socket = null
        target = null
        _state.value = State.Idle
    }

    companion object {
        private const val TAG = "MotionSender"
    }
}
