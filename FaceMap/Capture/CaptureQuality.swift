import Foundation

/// Per-capture quality assessment, computed at snapshot time from the frame buffer,
/// the photo-frame head pose, and the capture gates. Persisted inside the
/// `CapturedFace` blob so the Analysis screen (and future confidence weighting)
/// can tell a steady, gated capture from a rushed manual one.
struct CaptureQuality: Codable, Hashable {
    /// Topology-matched samples that went into the aggregated mesh (1...10).
    let framesAveraged: Int
    /// Mean over vertices of the per-vertex temporal standard deviation, in millimeters.
    let meanJitterMM: Float
    /// Worst per-vertex temporal standard deviation, in millimeters.
    let maxJitterMM: Float
    /// |yaw − pose target| at the photo frame, degrees.
    let yawErrorDegrees: Float
    /// Photo-frame pitch, degrees (target is 0 for all poses).
    let pitchDegrees: Float
    /// Photo-frame roll, degrees (target is 0 for all poses).
    let rollDegrees: Float
    /// Max over the gated blendshapes of value/threshold — 1.0 means exactly at a gate limit.
    let expressionMax: Float
    /// `CaptureGate.Violation` rawValues active at snapshot. Empty for a gated auto
    /// capture; possibly non-empty for a manual capture (the practitioner's escape hatch).
    let gateViolations: [String]
    /// Composite 0–1 score. Good ≥ 0.80, Fair 0.60–0.80, Poor < 0.60.
    let composite: Float

    enum Band: String {
        case good, fair, poor

        var label: String {
            switch self {
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
    }

    var band: Band {
        if composite >= 0.80 { return .good }
        if composite >= 0.60 { return .fair }
        return .poor
    }

    /// Builds a quality record, deriving the composite from the raw signals.
    ///
    /// Weights: jitter 0.35 (directly bounds mesh geometric fidelity), pose 0.30
    /// (texture projection + transform-dependent metrics), expression 0.25 (local
    /// region distortion), frame count 0.10 (minor stability signal). Each subscore
    /// reaches 0 at roughly 2–3× its gate tolerance.
    static func compute(framesAveraged: Int,
                        meanJitterMM: Float,
                        maxJitterMM: Float,
                        yawErrorDegrees: Float,
                        pitchDegrees: Float,
                        rollDegrees: Float,
                        expressionMax: Float,
                        gateViolations: [String]) -> CaptureQuality {
        func clamp01(_ x: Float) -> Float { min(max(x, 0), 1) }

        // 0.5 mm mean temporal jitter is unusable relative to the surface-change
        // analyzer's 0.3 mm noise floor.
        let sJitter = clamp01(1 - meanJitterMM / 0.5)
        // Score hits 0 at 3× each gate tolerance (yaw 5°, pitch 10°, roll 7°).
        let maxAxisRatio = max(abs(yawErrorDegrees) / 15,
                               abs(pitchDegrees) / 30,
                               abs(rollDegrees) / 21)
        let sPose = clamp01(1 - maxAxisRatio)
        // 1.0 when fully neutral, 0.5 exactly at the gate limit, 0 at 2×.
        let sExpr = clamp01(1 - expressionMax / 2)
        let sFrames = clamp01(Float(framesAveraged) / 10)

        let composite = 0.35 * sJitter + 0.30 * sPose + 0.25 * sExpr + 0.10 * sFrames

        return CaptureQuality(framesAveraged: framesAveraged,
                              meanJitterMM: meanJitterMM,
                              maxJitterMM: maxJitterMM,
                              yawErrorDegrees: yawErrorDegrees,
                              pitchDegrees: pitchDegrees,
                              rollDegrees: rollDegrees,
                              expressionMax: expressionMax,
                              gateViolations: gateViolations,
                              composite: composite)
    }
}
