import XCTest
import simd
@testable import FaceMap

final class MetricRegistryTests: XCTestCase {
    func test_defaultRegistry_hasAllShippedMetrics() {
        let r = MetricRegistry.defaultRegistry()
        let ids = r.metrics.map { $0.id }
        XCTAssertTrue(ids.contains(FacialThirdsMetric.id))
        XCTAssertTrue(ids.contains(FacialFifthsMetric.id))
        XCTAssertTrue(ids.contains(GoldenRatioMetric.id))
        XCTAssertTrue(ids.contains(CanthalTiltMetric.id))
        XCTAssertTrue(ids.contains(AsymmetryMetric.id))
        XCTAssertTrue(ids.contains(SurfaceDisplacementMetric.id))
        XCTAssertTrue(ids.contains(ExpressionAsymmetryMetric.id))
        XCTAssertEqual(ids.count, 7)
    }

    /// FAS facet assignments per FaceDomain.swift: proportions = thirds/fifths/golden
    /// ratio, symmetry = asymmetry + canthal tilt, facial shape = surface displacement.
    func test_metricDomainAssignments_matchFASFacets() {
        XCTAssertEqual(FacialThirdsMetric.domain, .proportions)
        XCTAssertEqual(FacialFifthsMetric.domain, .proportions)
        XCTAssertEqual(GoldenRatioMetric.domain, .proportions)
        XCTAssertEqual(CanthalTiltMetric.domain, .symmetry)
        XCTAssertEqual(AsymmetryMetric.domain, .symmetry)
        XCTAssertEqual(SurfaceDisplacementMetric.domain, .facialShape)
        XCTAssertEqual(ExpressionAsymmetryMetric.domain, .expression)
    }

    func test_evaluateAll_returnsOneResultPerMetric() {
        // Provide a face with enough plausible landmarks that no metric crashes.
        let face = SyntheticFace.make([
            .trichion:      SIMD3(0,  0.30, 0),
            .glabella:      SIMD3(0,  0.10, 0),
            .nasion:        SIMD3(0,  0.05, 0.01),
            .pronasale:     SIMD3(0, -0.02, 0.03),
            .subnasale:     SIMD3(0, -0.10, 0.01),
            .stomion:       SIMD3(0, -0.16, 0.01),
            .menton:        SIMD3(0, -0.30, 0),
            .pogonion:      SIMD3(0, -0.28, 0.01),
            .endocanthionR: SIMD3(-0.015, 0.08, 0),
            .exocanthionR:  SIMD3(-0.045, 0.085, 0),
            .endocanthionL: SIMD3( 0.015, 0.08, 0),
            .exocanthionL:  SIMD3( 0.045, 0.085, 0),
            .zygionR:       SIMD3(-0.075, 0.05, 0),
            .zygionL:       SIMD3( 0.075, 0.05, 0),
            .cheilionR:     SIMD3(-0.025, -0.16, 0),
            .cheilionL:     SIMD3( 0.025, -0.16, 0),
            .alarBaseR:     SIMD3(-0.018, -0.08, 0),
            .alarBaseL:     SIMD3( 0.018, -0.08, 0),
        ])
        let results = MetricRegistry.defaultRegistry().evaluateAll(on: face)
        XCTAssertEqual(results.count, 7)
    }

    func test_flaggedRegionsAggregation() {
        let badThirds = SyntheticFace.make([
            .trichion:  SIMD3(0,  0.3, 0),
            .glabella:  SIMD3(0, -0.1, 0),
            .subnasale: SIMD3(0, -0.2, 0),
            .menton:    SIMD3(0, -0.4, 0),
        ])
        let r = [FacialThirdsMetric().evaluate(badThirds)]
        let agg = r.flaggedRegionsBySeverity
        XCTAssertNotNil(agg[.forehead])
    }
}

// MARK: - Degenerate-input hardening

/// A zero-vertex face (e.g. a record whose mesh blob was lost) must flow through the
/// whole registry as per-metric "Unavailable" failure results — never a trap.
final class MetricRegistryDegenerateInputTests: XCTestCase {
    func test_evaluateAll_zeroVertexFace_returnsFailureResultForEveryMetric() {
        let face = AnalyzableFace(vertices: [])
        let registry = MetricRegistry.defaultRegistry()

        let results = registry.evaluateAll(on: face)

        XCTAssertEqual(results.count, registry.metrics.count,
                       "every metric must still report (as a failure), none may trap or vanish")
        for r in results {
            XCTAssertTrue(r.value.isNaN, "\(r.metricId) should report NaN, got \(r.value)")
            XCTAssertEqual(r.confidence, 0, "\(r.metricId) should report zero confidence")
            XCTAssertTrue(r.notes?.hasPrefix("Unavailable") ?? false,
                          "\(r.metricId) should carry an 'Unavailable' note, got \(r.notes ?? "nil")")
            XCTAssertTrue(r.regions.isEmpty, "\(r.metricId) must not flag regions it couldn't measure")
        }
        // And the aggregations downstream of evaluateAll stay empty rather than trapping.
        XCTAssertTrue(results.flaggedRegionsBySeverity.isEmpty)
    }
}
