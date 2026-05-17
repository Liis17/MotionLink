//
//  MotionManager.swift
//  MotionLink
//

import Foundation
import Observation
#if os(iOS)
import CoreMotion
#endif

struct MotionSnapshot: Codable, Sendable {
    var t: Double
    var roll: Double
    var pitch: Double
    var yaw: Double
    var acceleration: Vector3
    var gravity: Vector3
    var rotationRate: Vector3

    struct Vector3: Codable, Sendable {
        var x: Double
        var y: Double
        var z: Double
    }
}

@Observable
final class MotionManager {
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0

    var accelerationX: Double = 0
    var accelerationY: Double = 0
    var accelerationZ: Double = 0

    var gravityX: Double = 0
    var gravityY: Double = 0
    var gravityZ: Double = 0

    var rotationRateX: Double = 0
    var rotationRateY: Double = 0
    var rotationRateZ: Double = 0

    var isAvailable: Bool = false

    @ObservationIgnored
    var onUpdate: ((MotionSnapshot) -> Void)?

#if os(iOS)
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var timer: Timer?
#endif

    func start() {
#if os(iOS)
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }
        isAvailable = true
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
#endif
    }

    func stop() {
#if os(iOS)
        timer?.invalidate()
        timer = nil
        manager.stopDeviceMotionUpdates()
#endif
    }

#if os(iOS)
    private func tick() {
        guard let motion = manager.deviceMotion else { return }
        let rad2deg = 180.0 / .pi
        roll = motion.attitude.roll * rad2deg
        pitch = motion.attitude.pitch * rad2deg
        yaw = motion.attitude.yaw * rad2deg

        accelerationX = motion.userAcceleration.x
        accelerationY = motion.userAcceleration.y
        accelerationZ = motion.userAcceleration.z

        gravityX = motion.gravity.x
        gravityY = motion.gravity.y
        gravityZ = motion.gravity.z

        rotationRateX = motion.rotationRate.x
        rotationRateY = motion.rotationRate.y
        rotationRateZ = motion.rotationRate.z

        if let onUpdate {
            let snapshot = MotionSnapshot(
                t: Date().timeIntervalSince1970,
                roll: roll, pitch: pitch, yaw: yaw,
                acceleration: .init(x: accelerationX, y: accelerationY, z: accelerationZ),
                gravity: .init(x: gravityX, y: gravityY, z: gravityZ),
                rotationRate: .init(x: rotationRateX, y: rotationRateY, z: rotationRateZ)
            )
            onUpdate(snapshot)
        }
    }
#endif
}
