//
//  ContentView.swift
//  MotionLink
//
//  Created by Li_is on 17/05/2026.
//

import SwiftUI

enum AppState: Equatable {
    case searching
    case streaming(DiscoveredServer)
}

struct ContentView: View {
    @State private var state: AppState = .searching
    @State private var motion = MotionManager()
    @State private var discovery = DiscoveryService()
    @State private var sender = MotionSender()

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            content
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .animation(.smooth(duration: 0.35), value: stateID)
        .preferredColorScheme(.light)
        .onAppear { discovery.start() }
        .onDisappear { teardown() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .searching:
            DiscoveryView(servers: discovery.servers, onConnect: connect)
        case .streaming(let server):
            MotionHUDView(
                motion: motion,
                server: server,
                isConnected: sender.isConnected,
                onDisconnect: disconnect
            )
        }
    }

    private var stateID: Int {
        switch state {
        case .searching: return 0
        case .streaming: return 1
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(white: 1.0),
                Color(white: 0.94)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func connect(to server: DiscoveredServer) {
        discovery.stop()
        sender.start(host: server.host, port: server.port)
        motion.onUpdate = { [sender] snapshot in
            sender.send(snapshot)
        }
        motion.start()
        state = .streaming(server)
    }

    private func disconnect() {
        motion.stop()
        motion.onUpdate = nil
        sender.stop()
        discovery.start()
        state = .searching
    }

    private func teardown() {
        motion.stop()
        motion.onUpdate = nil
        sender.stop()
        discovery.stop()
    }
}

#Preview {
    ContentView()
}
