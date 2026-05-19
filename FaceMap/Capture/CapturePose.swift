import Foundation

/// The three head poses the coached capture flow walks through. Each captures a
/// `CapturedFace` from a different yaw angle so subsequent analysis can see
/// features that are invisible from the front (nose bumps, chin projection, etc.).
enum CapturePose: String, Codable, CaseIterable, Hashable, Identifiable {
    /// Yaw ≈ 0°.
    case frontal
    /// Patient turned to their right by ~30°. Shows the **patient's left** side.
    /// In our `HeadPose` convention (yaw > 0 = camera-right), this is **yaw ≈ -30°**.
    case obliqueL
    /// Patient turned to their left by ~30°. Shows the **patient's right** side.
    /// Yaw ≈ +30°.
    case obliqueR

    var id: String { rawValue }

    /// Short label for the pose picker. The L/R refers to which side of the patient
    /// is visible to the camera.
    var label: String {
        switch self {
        case .frontal:  return "Front"
        case .obliqueL: return "¾ L"
        case .obliqueR: return "¾ R"
        }
    }

    var displayName: String {
        switch self {
        case .frontal:  return "Frontal"
        case .obliqueL: return "Oblique left"
        case .obliqueR: return "Oblique right"
        }
    }

    /// Target yaw in degrees for this pose. ±5° of this counts as "in range".
    var targetYawDegrees: Double {
        switch self {
        case .frontal:  return  0
        case .obliqueL: return -30
        case .obliqueR: return  30
        }
    }

    var yawToleranceDegrees: Double { 5 }

    /// Phrased from the patient's perspective ("turn your head…") because the
    /// practitioner holding the phone is directing them.
    var coachPrompt: String {
        switch self {
        case .frontal:  return "Look straight at the camera"
        case .obliqueL: return "Slowly turn your head to your right"
        case .obliqueR: return "Slowly turn your head to your left"
        }
    }

    func contains(yawDegrees: Double) -> Bool {
        abs(yawDegrees - targetYawDegrees) <= yawToleranceDegrees
    }

    /// Signed distance from the pose's target yaw, in degrees.
    /// Positive = patient needs to turn further toward camera-right.
    func yawError(currentDegrees: Double) -> Double {
        targetYawDegrees - currentDegrees
    }
}
