import Foundation
import simd

/// Named anatomical landmarks used by the v0.1 metrics.
/// Definitions follow standard cephalometric conventions where applicable.
///
/// All accessors are derived from indices in `FaceLandmarkIndices`.
enum AnatomicalLandmark: String, CaseIterable {
    /// Hairline midpoint at the top of the forehead.
    case trichion
    /// Most anterior midpoint of the forehead between the eyebrows.
    case glabella
    /// Deepest midpoint of the nasal root (between the eyes).
    case nasion
    /// Tip of the nose.
    case pronasale
    /// Midpoint of the columella where it meets the upper lip.
    case subnasale
    /// Midline contact point between upper and lower lips.
    case stomion
    /// Most anterior midpoint of the chin.
    case pogonion
    /// Lowest midpoint of the chin (along the mandibular border).
    case menton

    /// Inner (medial) corner of the right eye.
    case endocanthionR
    /// Outer (lateral) corner of the right eye.
    case exocanthionR
    /// Inner (medial) corner of the left eye.
    case endocanthionL
    /// Outer (lateral) corner of the left eye.
    case exocanthionL

    /// Most lateral point of the right cheekbone (zygomatic arch).
    case zygionR
    /// Most lateral point of the left cheekbone.
    case zygionL

    /// Right corner of the mouth.
    case cheilionR
    /// Left corner of the mouth.
    case cheilionL

    /// Right alar base of the nose (where the nostril meets the cheek).
    case alarBaseR
    /// Left alar base.
    case alarBaseL
}

extension AnatomicalLandmark {
    /// Short human-readable name shown to practitioners during calibration.
    var displayLabel: String {
        switch self {
        case .trichion:      return "Trichion"
        case .glabella:      return "Glabella"
        case .nasion:        return "Nasion"
        case .pronasale:     return "Pronasale"
        case .subnasale:     return "Subnasale"
        case .stomion:       return "Stomion"
        case .pogonion:      return "Pogonion"
        case .menton:        return "Menton"
        case .endocanthionR: return "Endocanthion R"
        case .exocanthionR:  return "Exocanthion R"
        case .endocanthionL: return "Endocanthion L"
        case .exocanthionL:  return "Exocanthion L"
        case .zygionR:       return "Zygion R"
        case .zygionL:       return "Zygion L"
        case .cheilionR:     return "Cheilion R"
        case .cheilionL:     return "Cheilion L"
        case .alarBaseR:     return "Alar base R"
        case .alarBaseL:     return "Alar base L"
        }
    }

    /// One-line cue for the user to find the landmark on the mesh.
    var calibrationHint: String {
        switch self {
        case .trichion:      return "Top of the forehead at the hairline midline."
        case .glabella:      return "Most anterior midpoint between the eyebrows."
        case .nasion:        return "Deepest midpoint of the nasal root, between the eyes."
        case .pronasale:     return "Tip of the nose."
        case .subnasale:     return "Where the columella meets the upper lip (under the nose)."
        case .stomion:       return "Midline contact point between upper and lower lips."
        case .pogonion:      return "Most anterior midpoint of the chin."
        case .menton:        return "Lowest midpoint of the chin."
        case .endocanthionR: return "Inner corner of the patient's right eye."
        case .exocanthionR:  return "Outer corner of the patient's right eye."
        case .endocanthionL: return "Inner corner of the patient's left eye."
        case .exocanthionL:  return "Outer corner of the patient's left eye."
        case .zygionR:       return "Most lateral point of the right cheekbone."
        case .zygionL:       return "Most lateral point of the left cheekbone."
        case .cheilionR:     return "Right corner of the mouth."
        case .cheilionL:     return "Left corner of the mouth."
        case .alarBaseR:     return "Right alar base — where the nostril meets the cheek."
        case .alarBaseL:     return "Left alar base."
        }
    }

    /// Suggested calibration order: midline first (top → bottom), then symmetric pairs.
    static let calibrationOrder: [AnatomicalLandmark] = [
        .trichion, .glabella, .nasion,
        .endocanthionR, .endocanthionL, .exocanthionR, .exocanthionL,
        .pronasale, .alarBaseR, .alarBaseL, .subnasale,
        .cheilionR, .cheilionL, .stomion,
        .zygionR, .zygionL,
        .pogonion, .menton,
    ]
}
