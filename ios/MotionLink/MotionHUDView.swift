//
//  MotionHUDView.swift
//  MotionLink
//

import SwiftUI

struct MotionHUDView: View {
    let motion: MotionManager
    let server: DiscoveredServer
    let isConnected: Bool
    let onDisconnect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            connectionBadge
                .padding(.top, 12)

            Spacer(minLength: 16)

            if motion.isAvailable {
                readout
                    .frame(maxWidth: 420)
                    .padding(.horizontal, 32)
            } else {
                unavailable
            }

            Spacer(minLength: 16)

            disconnectButton
                .padding(.bottom, 16)
        }
    }

    private var connectionBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color(red: 0.20, green: 0.78, blue: 0.35) : Color.black.opacity(0.25))
                .frame(width: 6, height: 6)
            Text("\(server.host):\(String(server.port))")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(.black.opacity(0.5))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule().fill(.black.opacity(0.04))
        )
    }

    private var readout: some View {
        VStack(spacing: 36) {
            section(title: "Поворот") {
                row(label: "Roll",  value: motion.roll,  unit: "°")
                row(label: "Pitch", value: motion.pitch, unit: "°")
                row(label: "Yaw",   value: motion.yaw,   unit: "°")
            }

            separator

            section(title: "Гравитация") {
                row(label: "X", value: motion.gravityX, unit: "g", decimals: 3)
                row(label: "Y", value: motion.gravityY, unit: "g", decimals: 3)
                row(label: "Z", value: motion.gravityZ, unit: "g", decimals: 3)
            }

            separator

            section(title: "Ускорение") {
                row(label: "X", value: motion.accelerationX, unit: "g", decimals: 3)
                row(label: "Y", value: motion.accelerationY, unit: "g", decimals: 3)
                row(label: "Z", value: motion.accelerationZ, unit: "g", decimals: 3)
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(width: 48, height: 1)
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .tracking(3)
                .foregroundStyle(.black.opacity(0.4))

            VStack(spacing: 4) {
                content()
            }
        }
    }

    private func row(label: String, value: Double, unit: String, decimals: Int = 1) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.4))
                .frame(width: 44, alignment: .leading)

            Text(formatted(value, decimals: decimals))
                .font(.system(size: 30, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentTransition(.numericText(value: value))

            Text(unit)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.4))
                .frame(width: 18, alignment: .leading)
        }
    }

    private var unavailable: some View {
        VStack(spacing: 10) {
            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.black.opacity(0.3))
            Text("Датчики недоступны")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.5))
            Text("Откройте на iPhone или iPad")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.3))
        }
    }

    private var disconnectButton: some View {
        Button(action: onDisconnect) {
            Text("Отключиться")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.black.opacity(0.45))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    Capsule().fill(.black.opacity(0.04))
                )
        }
        .buttonStyle(.plain)
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        String(format: "%+.\(decimals)f", value)
    }
}
