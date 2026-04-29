import Foundation

/// Central place to register and run all `FaceMetric` implementations.
/// Adding a metric in v0.2+ = call `register(_:)` in `defaultRegistry()`.
struct MetricRegistry {
    private(set) var metrics: [any FaceMetric]

    init(metrics: [any FaceMetric]) {
        self.metrics = metrics
    }

    /// Run every registered metric over the given face.
    func evaluateAll(on face: AnalyzableFace) -> [MetricResult] {
        metrics.map { $0.evaluate(face) }
    }

    /// Default v0.1 metric set.
    static func defaultRegistry() -> MetricRegistry {
        MetricRegistry(metrics: [
            FacialThirdsMetric(),
            FacialFifthsMetric(),
            GoldenRatioMetric(),
            CanthalTiltMetric(),
            AsymmetryMetric(),
        ])
    }
}

extension Array where Element == MetricResult {
    private static let severityOrder: [MetricResult.Severity] = [.normal, .mild, .moderate, .significant]

    /// Aggregate flagged regions across all results. A region appears once even if multiple
    /// metrics flag it. The associated severity is the worst across implicating metrics.
    var flaggedRegionsBySeverity: [FacialRegion: MetricResult.Severity] {
        var out: [FacialRegion: MetricResult.Severity] = [:]
        for r in self where !r.isWithinTarget {
            for region in r.regions {
                let prev = out[region] ?? .normal
                if (Self.severityOrder.firstIndex(of: r.severity) ?? 0) >
                   (Self.severityOrder.firstIndex(of: prev) ?? 0) {
                    out[region] = r.severity
                }
            }
        }
        return out
    }

    /// For each flagged region, the domain of the metric that contributed the worst severity.
    /// Used by visualisations that want to colour a region in its dominant-metric's hue.
    var regionDomainsByWorstSeverity: [FacialRegion: FaceDomain] {
        var bestSeverity: [FacialRegion: MetricResult.Severity] = [:]
        var domainOut:    [FacialRegion: FaceDomain] = [:]
        for r in self where !r.isWithinTarget {
            for region in r.regions {
                let prev = bestSeverity[region] ?? .normal
                if (Self.severityOrder.firstIndex(of: r.severity) ?? 0) >
                   (Self.severityOrder.firstIndex(of: prev) ?? 0) {
                    bestSeverity[region] = r.severity
                    domainOut[region]    = r.domain
                }
            }
        }
        return domainOut
    }
}
