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
