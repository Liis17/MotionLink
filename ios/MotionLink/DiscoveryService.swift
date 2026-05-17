//
//  DiscoveryService.swift
//  MotionLink
//

import Foundation
import Observation
import Darwin
import Network

struct DiscoveredServer: Identifiable, Hashable, Sendable {
    let host: String
    let port: UInt16
    let name: String?

    var id: String { host }
}

@Observable
final class DiscoveryService {
    static let discoveryPort: UInt16 = 58930
    private static let probe = "MOTIONLINK_DISCOVER\n"

    private(set) var servers: [DiscoveredServer] = []
    private(set) var isSearching: Bool = false

    @ObservationIgnored private var sock: Int32 = -1
    @ObservationIgnored private var probeTimer: DispatchSourceTimer?
    @ObservationIgnored private var receiveSource: DispatchSourceRead?
    @ObservationIgnored private var permissionBrowser: NWBrowser?
    @ObservationIgnored private let queue = DispatchQueue(label: "motionlink.discovery")

    func start() {
        guard sock < 0 else { return }

        triggerLocalNetworkPermission()

        guard openSocket() else { return }

        isSearching = true

        let read = DispatchSource.makeReadSource(fileDescriptor: sock, queue: queue)
        read.setEventHandler { [weak self] in self?.receive() }
        read.resume()
        receiveSource = read

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in self?.sendProbe() }
        timer.resume()
        probeTimer = timer
    }

    func stop() {
        probeTimer?.cancel()
        probeTimer = nil
        receiveSource?.cancel()
        receiveSource = nil
        if sock >= 0 {
            close(sock)
            sock = -1
        }
        permissionBrowser?.cancel()
        permissionBrowser = nil
        isSearching = false
    }

    // iOS 14+ silently blocks broadcast/multicast until the user grants Local
    // Network permission. The system prompt is only triggered by Network
    // framework APIs — raw POSIX sockets won't bring it up. This dummy NWBrowser
    // exists purely to wake the permission dialog so our broadcast probes
    // actually leave the device.
    private func triggerLocalNetworkPermission() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_motionlink._udp.", domain: nil)
        let params = NWParameters()
        params.includePeerToPeer = false
        let browser = NWBrowser(for: descriptor, using: params)
        browser.browseResultsChangedHandler = { _, _ in }
        browser.stateUpdateHandler = { _ in }
        browser.start(queue: queue)
        permissionBrowser = browser
    }

    private func openSocket() -> Bool {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { return false }

        var yes: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr.s_addr = in_addr_t(0)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                Darwin.bind(fd, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            close(fd)
            return false
        }

        sock = fd
        return true
    }

    private func sendProbe() {
        guard sock >= 0 else { return }
        var dest = sockaddr_in()
        dest.sin_family = sa_family_t(AF_INET)
        dest.sin_port = Self.discoveryPort.bigEndian
        dest.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        inet_pton(AF_INET, "255.255.255.255", &dest.sin_addr)

        let payload = Array(Self.probe.utf8)
        _ = payload.withUnsafeBufferPointer { buf -> Int in
            withUnsafePointer(to: &dest) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    sendto(sock, buf.baseAddress, buf.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    private func receive() {
        guard sock >= 0 else { return }
        var buffer = [UInt8](repeating: 0, count: 2048)
        var addr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        let n = buffer.withUnsafeMutableBufferPointer { buf -> Int in
            withUnsafeMutablePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    recvfrom(sock, buf.baseAddress, buf.count, 0, sa, &addrLen)
                }
            }
        }
        guard n > 0 else { return }

        let data = Data(buffer.prefix(n))
        guard let host = ipString(from: addr) else { return }

        // Filter out our own probes (some networks reflect broadcasts back).
        if data.starts(with: Array(Self.probe.utf8)) { return }

        let parsed = parseReply(data)
        let server = DiscoveredServer(
            host: host,
            port: parsed.port ?? Self.discoveryPort,
            name: parsed.name
        )
        addServer(server)
    }

    private func parseReply(_ data: Data) -> (name: String?, port: UInt16?) {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let name = json["name"] as? String
            let port = (json["port"] as? Int).flatMap { UInt16(exactly: $0) }
            return (name, port)
        }
        return (nil, nil)
    }

    private func ipString(from addr: sockaddr_in) -> String? {
        var addr = addr
        var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let result = inet_ntop(AF_INET, &addr.sin_addr, &buf, socklen_t(INET_ADDRSTRLEN))
        guard result != nil else { return nil }
        return String(cString: buf)
    }

    private func addServer(_ server: DiscoveredServer) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.servers.contains(server) {
                self.servers.append(server)
            }
        }
    }
}
