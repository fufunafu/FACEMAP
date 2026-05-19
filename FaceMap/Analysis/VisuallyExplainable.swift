import Foundation

/// A `FaceMetric` that can describe how it derived its value as a geometric
/// construction on the captured mesh (lines, centroids, angle markers, etc.).
/// Returning `nil` from `construction(for:)` means this metric has no useful
/// visual explanation (or can't produce one for the given face).
///
/// Default conformance via the `FaceMetric` extension below is a no-op — only
/// metrics that explicitly implement `construction(for:)` show overlays.
protocol VisuallyExplainable {
    func construction(for face: AnalyzableFace) -> MetricConstruction?
}

extension FaceMetric {
    /// Default: no construction. Metrics that opt in override this in an extension.
    func construction(for face: AnalyzableFace) -> MetricConstruction? { nil }
}
