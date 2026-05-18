//
//  DiscoveryView.swift
//  MotionLink
//

import SwiftUI

struct DiscoveryView: View {
    let servers: [DiscoveredServer]
    let onConnect: (DiscoveredServer) -> Void

    @State private var showManualEntry = false

    var body: some View {
        VStack(spacing: 32) {
            icon

            if servers.isEmpty {
                searching
            } else {
                serverList
            }

            manualEntryButton
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 380)
        .sheet(isPresented: $showManualEntry) {
            ManualServerEntryView { server in
                showManualEntry = false
                onConnect(server)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var manualEntryButton: some View {
        Button {
            showManualEntry = true
        } label: {
            Text("Ввести адрес вручную")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.55))
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    Capsule()
                        .stroke(.black.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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

private struct ManualServerEntryView: View {
    let onConnect: (DiscoveredServer) -> Void

    @State private var host: String = ""
    @State private var portText: String = String(DiscoveryService.discoveryPort)
    @FocusState private var focusedField: Field?

    private enum Field { case host, port }

    private var trimmedHost: String {
        host.trimmingCharacters(in: .whitespaces)
    }

    private var parsedPort: UInt16? {
        UInt16(portText.trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        !trimmedHost.isEmpty && parsedPort != nil
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Адрес сервера")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text("UDP-порт по умолчанию — \(String(DiscoveryService.discoveryPort))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.black.opacity(0.45))
            }
            .padding(.top, 28)

            VStack(spacing: 12) {
                field(
                    title: "Хост / IP",
                    text: $host,
                    placeholder: "192.168.1.42",
                    keyboard: .URL,
                    field: .host
                )
                field(
                    title: "Порт",
                    text: $portText,
                    placeholder: "58930",
                    keyboard: .numberPad,
                    field: .port
                )
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            Button(action: submit) {
                Text("Подключиться")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(isValid ? .black.opacity(0.88) : .black.opacity(0.3))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { focusedField = .host }
    }

    @ViewBuilder
    private func field(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.black.opacity(0.45))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .font(.system(size: 16, design: .monospaced))
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black.opacity(0.04))
                )
        }
    }

    private func submit() {
        guard isValid, let port = parsedPort else { return }
        let server = DiscoveredServer(
            host: trimmedHost,
            port: port,
            name: nil
        )
        onConnect(server)
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
