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
    /// Which quadrant of Dr Nikolis's four-domain framework this metric belongs to.
    static var domain: FaceDomain { get }
    /// Regions this metric *can* implicate. Used for UI grouping.
    var regions: [FacialRegion] { get }

    func evaluate(_ face: AnalyzableFace) -> MetricResult
}

extension FaceMetric {
    var id: String { Self.id }
    var displayName: String { Self.displayName }
    var domain: FaceDomain { Self.domain }
}

/// One outcome of evaluating a `FaceMetric` against a captured face.
struct MetricResult: Codable, Hashable {
    /// The metric ID this result came from.
    let metricId: String
    /// The metric's display name at evaluation time (denormalized for offline display).
    let metricName: String
    /// The four-domain bucket this metric belongs to (denormalized so old persisted results
    /// that pre-date the framework still render correctly).
    let domain: FaceDomain
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

    // Custom decoding so v0.1-era results (no `domain` field) still load — they all
    // came from Symmetry-domain metrics.
    private enum CodingKeys: String, CodingKey {
        case metricId, metricName, domain, value, target, deviation, confidence, regions, notes
    }

    init(metricId: String, metricName: String, domain: FaceDomain,
         value: Double, target: ClosedRange<Double>, deviation: Double,
         confidence: Double, regions: [FacialRegion], notes: String?) {
        self.metricId = metricId
        self.metricName = metricName
        self.domain = domain
        self.value = value
        self.target = target
        self.deviation = deviation
        self.confidence = confidence
        self.regions = regions
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        metricId   = try c.decode(String.self, forKey: .metricId)
        metricName = try c.decode(String.self, forKey: .metricName)
        domain     = try c.decodeIfPresent(FaceDomain.self, forKey: .domain) ?? .symmetry
        value      = try c.decode(Double.self, forKey: .value)
        target     = try c.decode(ClosedRange<Double>.self, forKey: .target)
        deviation  = try c.decode(Double.self, forKey: .deviation)
        confidence = try c.decode(Double.self, forKey: .confidence)
        regions    = try c.decode([FacialRegion].self, forKey: .regions)
        notes      = try c.decodeIfPresent(String.self, forKey: .notes)
    }

    /// Copy with the confidence attenuated by a 0–1 factor — used to fold the
    /// capture-quality composite into per-metric confidence (a metric evaluated on
    /// a shaky, off-pose capture is less trustworthy than the same metric on a
    /// clean one). Metrics keep reporting their intrinsic confidence; the capture
    /// factor is applied once, after evaluation.
    func scalingConfidence(by factor: Double) -> MetricResult {
        MetricResult(metricId: metricId, metricName: metricName, domain: domain,
                     value: value, target: target, deviation: deviation,
                     confidence: confidence * min(max(factor, 0), 1),
                     regions: regions, notes: notes)
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
