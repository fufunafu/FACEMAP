import Foundation

/// Capture-readiness gates evaluated every frame. Auto-capture only fires when
/// `evaluate` returns no violations for the full hold duration; manual capture
/// bypasses the gates but records active violations in `CaptureQuality`.
///
/// Thresholds are centralized here so clinical tuning is a one-line change.
enum CaptureGate {

    enum Violation: String, CaseIterable {
        case yawOutOfWindow
        case pitchTilted
        case rollTilted
        case jawOpen
        case smiling
        case browRaised
        case eyesClosed

        /// One-line coaching copy for the capture screen's status banner. Phrased
        /// from the patient's perspective because the practitioner is directing them.
        var coachingText: String {
            switch self {
            case .yawOutOfWindow: return "Turn to the target angle"
            case .pitchTilted:    return "Keep the chin level — look straight ahead"
            case .rollTilted:     return "Straighten the head — ears level"
            case .jawOpen:        return "Close the mouth gently"
            case .smiling:        return "Relax the face — neutral expression"
            case .browRaised:     return "Relax the brow"
            case .eyesClosed:     return "Keep both eyes open"
            }
        }
    }

    // Pose tolerances (degrees). Yaw uses the per-pose window on `CapturePose`.
    // Roll is tighter than pitch because roll directly fakes asymmetry and canthal
    // tilt readings; pitch mostly degrades the photo/texture (users naturally hold
    // phones slightly below eye level, so it gets more slack).
    static let pitchToleranceDegrees: Double = 10
    static let rollToleranceDegrees: Double = 7

    // Blendshape thresholds. Chosen to allow a relaxed resting face (lips parted,
    // resting brow tone, naturally narrow eyes) while rejecting real expressions
    // that deform the regions the metrics measure.
    static let jawOpenMax: Float = 0.15
    static let mouthSmileMax: Float = 0.20
    static let browInnerUpMax: Float = 0.25
    static let eyeBlinkMax: Float = 0.35

    /// Gated blendshapes with their thresholds (ARKit rawValue keys).
    private static let expressionGates: [(keys: [String], max: Float, violation: Violation)] = [
        (["jawOpen"], jawOpenMax, .jawOpen),
        (["mouthSmile_L", "mouthSmile_R"], mouthSmileMax, .smiling),
        (["browInnerUp"], browInnerUpMax, .browRaised),
        (["eyeBlink_L", "eyeBlink_R"], eyeBlinkMax, .eyesClosed),
    ]

    /// All violations for the current frame, ordered worst-first: pose identity
    /// (yaw) first, then level-ness (pitch, roll), then expression.
    static func evaluate(targetPose: CapturePose,
                         pose: HeadPose,
                         blendShapes: [String: Float]) -> [Violation] {
        var out: [Violation] = []
        if !targetPose.contains(yawDegrees: pose.yawDegrees) {
            out.append(.yawOutOfWindow)
        }
        if abs(pose.pitchDegrees) > pitchToleranceDegrees {
            out.append(.pitchTilted)
        }
        if abs(pose.rollDegrees) > rollToleranceDegrees {
            out.append(.rollTilted)
        }
        for gate in expressionGates {
            if gate.keys.contains(where: { (blendShapes[$0] ?? 0) > gate.max }) {
                out.append(gate.violation)
            }
        }
        return out
    }

    /// Max over the gated blendshapes of value/threshold — 1.0 means exactly at a
    /// gate limit. Feeds `CaptureQuality.expressionMax`.
    static func expressionRatio(blendShapes: [String: Float]) -> Float {
        var worst: Float = 0
        for gate in expressionGates {
            for key in gate.keys {
                worst = max(worst, (blendShapes[key] ?? 0) / gate.max)
            }
        }
        return worst
    }
}
