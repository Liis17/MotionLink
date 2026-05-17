package com.barkfluff.motionlink.discovery

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import com.barkfluff.motionlink.model.DiscoveredServer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketException

class DiscoveryService(context: Context) {

    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _servers = MutableStateFlow<List<DiscoveredServer>>(emptyList())
    val servers: StateFlow<List<DiscoveredServer>> = _servers.asStateFlow()

    private var socket: DatagramSocket? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var senderJob: Job? = null
    private var receiverJob: Job? = null

    fun start() {
        if (socket != null) return

        acquireMulticastLock()
        val sock = DatagramSocket(null).apply {
            reuseAddress = true
            broadcast = true
            bind(java.net.InetSocketAddress(0))
            soTimeout = 0
        }
        socket = sock

        receiverJob = scope.launch { receiveLoop(sock) }
        senderJob = scope.launch { broadcastLoop(sock) }
    }

    fun stop() {
        senderJob?.cancel(); senderJob = null
        receiverJob?.cancel(); receiverJob = null
        runCatching { socket?.close() }
        socket = null
        releaseMulticastLock()
        _servers.value = emptyList()
    }

    private suspend fun broadcastLoop(sock: DatagramSocket) {
        val payload = "MOTIONLINK_DISCOVER\n".toByteArray(Charsets.US_ASCII)
        val target = InetAddress.getByName("255.255.255.255")
        while (true) {
            try {
                sock.send(DatagramPacket(payload, payload.size, target, DISCOVERY_PORT))
            } catch (e: SocketException) {
                if (!scope.isActive) return
                Log.w(TAG, "broadcast send failed: ${e.message}")
            } catch (e: Exception) {
                Log.w(TAG, "broadcast send error: ${e.message}")
            }
            delay(1_000)
        }
    }

    private fun receiveLoop(sock: DatagramSocket) {
        val buf = ByteArray(2048)
        while (true) {
            val pkt = DatagramPacket(buf, buf.size)
            try {
                sock.receive(pkt)
            } catch (e: SocketException) {
                return
            } catch (e: Exception) {
                Log.w(TAG, "receive error: ${e.message}")
                continue
            }
            val host = pkt.address?.hostAddress ?: continue
            val data = pkt.data.copyOfRange(pkt.offset, pkt.offset + pkt.length)
            val text = data.toString(Charsets.UTF_8).trim()

            if (text.startsWith("MOTIONLINK_DISCOVER")) continue

            val (name, port) = parseResponse(text)
            val server = DiscoveredServer(host = host, port = port, name = name)
            addOrIgnore(server)
        }
    }

    private fun parseResponse(text: String): Pair<String?, Int> = try {
        val obj = JSONObject(text)
        val name = if (obj.has("name") && !obj.isNull("name")) {
            obj.optString("name", "").takeIf { it.isNotEmpty() }
        } else null
        val port = if (obj.has("port")) obj.optInt("port", DISCOVERY_PORT) else DISCOVERY_PORT
        name to port
    } catch (_: Exception) {
        null to DISCOVERY_PORT
    }

    private fun addOrIgnore(server: DiscoveredServer) {
        _servers.update { list ->
            if (list.any { it.id == server.id }) list
            else list + server
        }
    }

    private fun acquireMulticastLock() {
        if (multicastLock != null) return
        val wifi = appContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        multicastLock = wifi.createMulticastLock(TAG).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseMulticastLock() {
        multicastLock?.runCatching { if (isHeld) release() }
        multicastLock = null
    }

    companion object {
        private const val TAG = "DiscoveryService"
        const val DISCOVERY_PORT = 58930
    }
}
