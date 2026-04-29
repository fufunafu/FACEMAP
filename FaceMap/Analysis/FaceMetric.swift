import Foundation

/// A pluggable analysis. Implementations evaluate a captured face and return a numeric
/// result with a target range and the regions implicated when the value falls outside the target.
///
/// Adding a new metric in v0.2+ is a matter of writing a new type that conforms to this protocol
/// and registering it in `MetricRegistry`. No changes to capture, persistence, or visualization required.
protocol FaceMetric {
    /// Stable identifier used in persistence (e.g. "facial.thirds").
    static var id: String { get }
    /// Human-readable name shown in the analysis screen.
    static var displayName: String { get }
    /// Regions this metric *can* implicate. Used for UI grouping.
    var regions: [FacialRegion] { get }

    func evaluate(_ face: AnalyzableFace) -> MetricResult
}

extension FaceMetric {
    var id: String { Self.id }
    var displayName: String { Self.displayName }
}

/// One outcome of evaluating a `FaceMetric` against a captured face.
struct MetricResult: Codable, Hashable {
    /// The metric ID this result came from.
    let metricId: String
    /// The metric's display name at evaluation time (denormalized for offline display).
    let metricName: String
    /// The measured value (units depend on the metric — ratios are dimensionless, angles are degrees).
    let value: Double
    /// Accepted target range; `value in target` means within aesthetic norms.
    let target: ClosedRange<Double>
    /// Signed distance from the nearest target boundary (0 if inside the range).
    let deviation: Double
    /// Confidence in the measurement, 0…1. Currently a placeholder (1.0 by default).
    let confidence: Double
    /// Regions implicated by an out-of-range value. Empty when within target.
    let regions: [FacialRegion]
    /// Optional free-text annotation (e.g. which sub-ratio was off).
    let notes: String?

    var isWithinTarget: Bool { target.contains(value) }
    var severity: Severity {
        guard !isWithinTarget else { return .normal }
        let span = target.upperBound - target.lowerBound
        let mag = abs(deviation)
        if span > 0 && mag < span * 0.25 { return .mild }
        if span > 0 && mag < span * 0.75 { return .moderate }
        return .significant
    }

    enum Severity: String, Codable, Hashable {
        case normal, mild, moderate, significant
    }
}

/// Coarse anatomical regions used for visualization and aggregation across metrics.
/// Suffix `L` / `R` marks the patient's left / right (mirror of camera view).
enum FacialRegion: String, Codable, Hashable, CaseIterable {
    case forehead
    case templeL, templeR
    case browL, browR
    case tearTroughL, tearTroughR
    case midfaceL, midfaceR              // cheek apex
    case nasolabialL, nasolabialR
    case lipUpper, lipLower, perioral
    case marionetteL, marionetteR
    case chin
    case prejowlL, prejowlR
    case jawlineL, jawlineR

    var displayName: String {
        switch self {
        case .forehead: return "Forehead"
        case .templeL: return "Temple (L)"
        case .templeR: return "Temple (R)"
        case .browL: return "Brow (L)"
        case .browR: return "Brow (R)"
        case .tearTroughL: return "Tear trough (L)"
        case .tearTroughR: return "Tear trough (R)"
        case .midfaceL: return "Midface (L)"
        case .midfaceR: return "Midface (R)"
        case .nasolabialL: return "Nasolabial fold (L)"
        case .nasolabialR: return "Nasolabial fold (R)"
        case .lipUpper: return "Upper lip"
        case .lipLower: return "Lower lip"
        case .perioral: return "Perioral"
        case .marionetteL: return "Marionette (L)"
        case .marionetteR: return "Marionette (R)"
        case .chin: return "Chin"
        case .prejowlL: return "Pre-jowl (L)"
        case .prejowlR: return "Pre-jowl (R)"
        case .jawlineL: return "Jawline (L)"
        case .jawlineR: return "Jawline (R)"
        }
    }
}
