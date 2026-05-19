import Foundation

/// Bundle of `CapturedFace` keyed by `CapturePose`. The frontal pose is required;
/// the two obliques are optional so single-pose flows (legacy patient records,
/// partial captures) continue to work.
struct MultiPoseCapture: Hashable {
    let frontal: CapturedFace
    var obliqueL: CapturedFace?
    var obliqueR: CapturedFace?

    init(frontal: CapturedFace, obliqueL: CapturedFace? = nil, obliqueR: CapturedFace? = nil) {
        self.frontal = frontal
        self.obliqueL = obliqueL
        self.obliqueR = obliqueR
    }

    /// Returns the captured face for the given pose, falling back to the frontal capture.
    func face(for pose: CapturePose) -> CapturedFace {
        switch pose {
        case .frontal:  return frontal
        case .obliqueL: return obliqueL ?? frontal
        case .obliqueR: return obliqueR ?? frontal
        }
    }

    /// Poses that have a real (non-fallback) capture available.
    var availablePoses: [CapturePose] {
        var out: [CapturePose] = [.frontal]
        if obliqueL != nil { out.append(.obliqueL) }
        if obliqueR != nil { out.append(.obliqueR) }
        return out
    }

    var isComplete: Bool { obliqueL != nil && obliqueR != nil }
}
