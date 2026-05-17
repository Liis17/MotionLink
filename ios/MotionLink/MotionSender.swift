//
//  MotionSender.swift
//  MotionLink
//

import Foundation
import Network
import Observation

@Observable
final class MotionSender {
    private(set) var isConnected: Bool = false
    private(set) var lastSentAt: Date?

    @ObservationIgnored private var connection: NWConnection?
    @ObservationIgnored private let queue = DispatchQueue(label: "motionlink.sender")
    @ObservationIgnored private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = []
        return e
    }()

    func start(host: String, port: UInt16) {
        stop()
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
        let nwHost = NWEndpoint.Host(host)
        let conn = NWConnection(host: nwHost, port: nwPort, using: .udp)
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            let connected: Bool
            switch state {
            case .ready: connected = true
            case .failed, .cancelled, .setup, .preparing, .waiting: connected = false
            @unknown default: connected = false
            }
            DispatchQueue.main.async {
                self.isConnected = connected
            }
        }
        conn.start(queue: queue)
        connection = conn
    }

    func send(_ snapshot: MotionSnapshot) {
        guard let connection else { return }
        guard let data = try? encoder.encode(snapshot) else { return }
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            guard error == nil, let self else { return }
            DispatchQueue.main.async {
                self.lastSentAt = Date()
            }
        })
    }

    func stop() {
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
        }
    }
}
