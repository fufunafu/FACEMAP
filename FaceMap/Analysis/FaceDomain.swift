import Foundation

/// The five facets of the **Facial Assessment Scale (FAS™)** as published in
/// Nikolis A et al., *Turn Your AART into a HIT…*, Clin Cosmet Investig Dermatol
/// 2024;17:2051–2069. Each facet has one or more sub-rows scored 0–3
/// (None / Mild / Moderate / Severe). See `FASRow` for the row enumeration.
///
/// The legacy type name `FaceDomain` is preserved (rather than renaming to
/// `FASFacet`) so that the existing data model — `MetricResult.domain`,
/// `regionDomainsByWorstSeverity`, persisted JSON — keeps loading. Cases now
/// match the paper.
enum FaceDomain: String, Codable, CaseIterable, Hashable, Identifiable {
    case skinQuality   // Loss of radiance/glow, Loss of firmness
    case facialShape   // Sagging, Volume loss
    case proportions   // Imbalance (thirds, fifths, golden ratio)
    case symmetry      // Asymmetry (incl. canthal tilt)
    case expression    // Static lines, Dynamic lines

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skinQuality: return "Skin quality"
        case .facialShape: return "Facial shape"
        case .proportions: return "Proportions"
        case .symmetry:    return "Symmetry"
        case .expression:  return "Expression"
        }
    }

    /// Position in the FAS™ wheel, top-clockwise.
    var wheelOrder: Int {
        switch self {
        case .skinQuality: return 0
        case .facialShape: return 1
        case .proportions: return 2
        case .symmetry:    return 3
        case .expression:  return 4
        }
    }

    /// Backwards-compat alias kept so older call sites compile.
    var wheelQuadrant: Int { wheelOrder }
}

// MARK: - Legacy aliases (pre-paper naming)
//
// The previous build named the four quadrants `mechanical / optical / symmetry /
// structural`. These properties keep ad-hoc references compiling during the
// transition. New code should use the canonical FAS facet cases above.
extension FaceDomain {
    static var mechanical: FaceDomain { .expression }     // line effacement, dynamic distortion
    static var optical:    FaceDomain { .skinQuality }    // surface abnormality, loss of shadows
    static var structural: FaceDomain { .facialShape }    // volume / sagging
}
