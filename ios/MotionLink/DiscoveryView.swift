//
//  DiscoveryView.swift
//  MotionLink
//

import SwiftUI

struct DiscoveryView: View {
    let servers: [DiscoveredServer]
    let onConnect: (DiscoveredServer) -> Void

    var body: some View {
        VStack(spacing: 32) {
            icon

            if servers.isEmpty {
                searching
            } else {
                serverList
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 380)
    }

    private var icon: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.system(size: 44, weight: .ultraLight))
            .foregroundStyle(.black.opacity(0.7))
            .symbolEffect(.variableColor.iterative.reversing, isActive: servers.isEmpty)
    }

    private var searching: some View {
        VStack(spacing: 8) {
            Text("Поиск сервера…")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.55))
            Text("UDP · \(String(DiscoveryService.discoveryPort))")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .monospacedDigit()
                .tracking(1)
                .foregroundStyle(.black.opacity(0.3))
        }
    }

    private var serverList: some View {
        VStack(spacing: 14) {
            Text(servers.count == 1 ? "Найден сервер" : "Найдено серверов: \(servers.count)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(3)
                .foregroundStyle(.black.opacity(0.4))

            VStack(spacing: 10) {
                ForEach(servers) { server in
                    Button {
                        onConnect(server)
                    } label: {
                        ServerCard(server: server)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ServerCard: View {
    let server: DiscoveredServer

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(server.name ?? "Сервер")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.8))
                Text("\(server.host):\(String(server.port))")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.45))
            }

            Spacer(minLength: 8)

            Text("Подключиться")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Capsule().fill(.black.opacity(0.88)))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        )
    }
}
