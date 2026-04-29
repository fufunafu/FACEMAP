import Foundation

/// Dr Andreas Nikolis's four-domain Facial Aesthetic framework.
/// Every `FaceMetric` declares which domain it evaluates so the analysis UI
/// can group results consistently and the Aesthetic Wheel can plot per-domain
/// severity at a glance.
enum FaceDomain: String, Codable, CaseIterable, Hashable, Identifiable {
    case mechanical   // line effacement, dynamic distortion
    case optical      // surface abnormality, loss of shadows
    case symmetry     // proportions, asymmetry, canthal tilt
    case structural   // periorbital / midface / lower-face volume

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mechanical: return "Mechanical behaviour"
        case .optical:    return "Optical properties"
        case .symmetry:   return "Symmetry & proportions"
        case .structural: return "Structural volume"
        }
    }

    /// Order around the wheel — top-left, top-right, bottom-left, bottom-right.
    /// Mirrors the published reference image.
    var wheelQuadrant: Int {
        switch self {
        case .mechanical: return 0  // top-left
        case .optical:    return 1  // top-right
        case .symmetry:   return 2  // bottom-left
        case .structural: return 3  // bottom-right
        }
    }
}
