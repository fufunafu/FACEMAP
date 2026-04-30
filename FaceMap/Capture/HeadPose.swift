import Foundation
import simd

/// Euler-angle decomposition of an `ARFaceAnchor.transform` into pitch/yaw/roll degrees.
/// Used by the capture screen to warn when the patient's head is not level — a tilted
/// head fakes apparent asymmetry, so the practitioner should know.
///
/// Sign convention (only useful for diagnostics; the threshold check uses magnitudes):
/// - **Pitch** > 0 when the chin lifts (head looks up).
/// - **Yaw**   > 0 when the head turns to the camera's right.
/// - **Roll**  > 0 when the head tilts clockwise from the camera's point of view.
struct HeadPose: Equatable {
    let pitchDegrees: Double
    let yawDegrees:   Double
    let rollDegrees:  Double

    var maxAbsoluteDegrees: Double {
        max(abs(pitchDegrees), abs(yawDegrees), abs(rollDegrees))
    }

    /// True when all three angles are within `tolerance` degrees of zero.
    func isLevel(within tolerance: Double = 5) -> Bool {
        maxAbsoluteDegrees <= tolerance
    }

    /// Names the worst-offending axis with its magnitude — feeds the capture-screen warning.
    var worstAxisDescription: String? {
        let p = abs(pitchDegrees), y = abs(yawDegrees), r = abs(rollDegrees)
        let worst = max(p, max(y, r))
        guard worst > 0 else { return nil }
        if worst == p {
            return String(format: "Head tilted %s by %.0f°",
                          pitchDegrees > 0 ? "up" : "down", abs(pitchDegrees))
        }
        if worst == y {
            return String(format: "Head turned %@ by %.0f°",
                          yawDegrees > 0 ? "right" : "left", abs(yawDegrees))
        }
        return String(format: "Head rolled %@ by %.0f°",
                      rollDegrees > 0 ? "clockwise" : "counter-clockwise", abs(rollDegrees))
    }

    /// Decompose a face → world transform into Euler angles.
    /// ARKit face-local frame: +X face's right, +Y up, +Z out of the face (toward camera).
    /// In a neutral pose the face's +Z aligns with world +Z and the face's +Y with world +Y.
    static func from(transform: simd_float4x4) -> HeadPose {
        // Face's forward axis (+Z) and up axis (+Y) in world space.
        let forward = SIMD3<Float>(transform.columns.2.x,
                                   transform.columns.2.y,
                                   transform.columns.2.z)
        let up = SIMD3<Float>(transform.columns.1.x,
                              transform.columns.1.y,
                              transform.columns.1.z)

        // Yaw: angle of the forward vector in the world XZ plane.
        let yaw   = Double(atan2(forward.x, forward.z)) * 180 / .pi
        // Pitch: forward vector's elevation above the world XZ plane.
        let clampedY = max(Float(-1), min(Float(1), forward.y))
        let pitch = Double(asin(clampedY)) * 180 / .pi
        // Roll: rotation of the up vector around the forward axis. For small pitch/yaw,
        // atan2(up.x, up.y) approximates the roll angle in degrees.
        let roll  = Double(atan2(up.x, up.y)) * 180 / .pi

        return HeadPose(pitchDegrees: pitch, yawDegrees: yaw, rollDegrees: roll)
    }
}
