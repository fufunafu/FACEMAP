import Foundation

/// Individual rows of the Facial Assessment Scale (FAS™) as published.
/// Seven rows, each scored 0–3. The row → facet mapping reproduces Figure 1
/// of Nikolis et al., 2024.
enum FASRow: String, Codable, CaseIterable, Hashable, Identifiable {
    case lossOfRadiance        // Skin quality
    case lossOfFirmness        // Skin quality
    case sagging               // Facial shape
    case volumeLoss            // Facial shape
    case proportionsImbalance  // Proportions
    case symmetryAsymmetry     // Symmetry
    case staticLines           // Expression
    case dynamicLines          // Expression

    var id: String { rawValue }

    var facet: FaceDomain {
        switch self {
        case .lossOfRadiance, .lossOfFirmness:    return .skinQuality
        case .sagging, .volumeLoss:               return .facialShape
        case .proportionsImbalance:               return .proportions
        case .symmetryAsymmetry:                  return .symmetry
        case .staticLines, .dynamicLines:         return .expression
        }
    }

    var displayName: String {
        switch self {
        case .lossOfRadiance:        return "Loss of radiance / glow"
        case .lossOfFirmness:        return "Loss of firmness"
        case .sagging:               return "Sagging"
        case .volumeLoss:            return "Volume loss"
        case .proportionsImbalance:  return "Imbalance"
        case .symmetryAsymmetry:     return "Asymmetry"
        case .staticLines:           return "Static lines"
        case .dynamicLines:          return "Dynamic lines"
        }
    }
}

// MARK: - FAS score (0–3)

/// The published 4-point severity scale. Maps cleanly to the existing
/// `MetricResult.Severity` ladder used throughout the app.
enum FASScore: Int, Codable, CaseIterable, Hashable {
    case none = 0, mild = 1, moderate = 2, severe = 3

    var label: String {
        switch self {
        case .none:     return "None"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .severe:   return "Severe"
        }
    }
}

extension MetricResult.Severity {
    /// Round-trip with the published 0–3 FAS scale.
    var fasScore: FASScore {
        switch self {
        case .normal:      return .none
        case .mild:        return .mild
        case .moderate:    return .moderate
        case .significant: return .severe
        }
    }
}
