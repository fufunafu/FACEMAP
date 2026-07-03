import XCTest
import simd
@testable import FaceMap

final class FrameAggregatorTests: XCTestCase {

    /// Ten identical frames of a small deterministic mesh.
    private func cleanSamples(vertexCount: Int = 20, frames: Int = 10) -> [[SIMD3<Float>]] {
        let base = (0..<vertexCount).map { i in
            SIMD3<Float>(Float(i) * 0.001, Float(i % 3) * 0.002, Float(i % 5) * 0.003)
        }
        return Array(repeating: base, count: frames)
    }

    func test_median_recoversTruth_withThreeOutlierFrames() {
        var samples = cleanSamples()
        let truth = samples[0]
        // 3 of 10 frames spiked +5 mm on x — a mean would shift by 1.5 mm.
        for f in 0..<3 {
            for i in samples[f].indices { samples[f][i].x += 0.005 }
        }
        let result = FrameAggregator.robustAverage(samples)
        for i in result.indices {
            XCTAssertEqual(result[i].x, truth[i].x, accuracy: 1e-6,
                           "median must be untouched by 3/10 outliers")
            XCTAssertEqual(result[i].y, truth[i].y, accuracy: 1e-6)
            XCTAssertEqual(result[i].z, truth[i].z, accuracy: 1e-6)
        }
    }

    func test_median_evenCount_averagesCentralPair() {
        // 4 frames with x = 1, 2, 10, 11 → median (2 + 10) / 2 = 6.
        let samples: [[SIMD3<Float>]] = [1, 2, 10, 11].map { [SIMD3(Float($0), 0, 0)] }
        let result = FrameAggregator.robustAverage(samples)
        XCTAssertEqual(result[0].x, 6, accuracy: 1e-6)
    }

    func test_singleSample_passesThrough() {
        let sample = [[SIMD3<Float>(0.1, 0.2, 0.3)]]
        XCTAssertEqual(FrameAggregator.robustAverage(sample), sample[0])
    }

    func test_emptyInput_returnsEmpty() {
        XCTAssertTrue(FrameAggregator.robustAverage([]).isEmpty)
        let stats = FrameAggregator.jitterStats([])
        XCTAssertEqual(stats.meanMM, 0)
        XCTAssertEqual(stats.maxMM, 0)
    }

    func test_jitterStats_zeroForIdenticalFrames() {
        // Tolerance 1e-4 mm (0.1 nm): identical frames still accumulate a few ULPs
        // of Float rounding in the mean/variance passes.
        let stats = FrameAggregator.jitterStats(cleanSamples())
        XCTAssertEqual(stats.meanMM, 0, accuracy: 1e-4)
        XCTAssertEqual(stats.maxMM, 0, accuracy: 1e-4)
    }

    func test_jitterStats_handComputed() {
        // One vertex oscillating ±1 mm on x across two frames:
        // mean 0, population variance = 1e-6 m², stddev = 1 mm.
        let samples: [[SIMD3<Float>]] = [
            [SIMD3(0.001, 0, 0), SIMD3(0, 0, 0)],
            [SIMD3(-0.001, 0, 0), SIMD3(0, 0, 0)],
        ]
        let stats = FrameAggregator.jitterStats(samples)
        XCTAssertEqual(stats.maxMM, 1.0, accuracy: 1e-4)
        // Second vertex is still → mean over vertices is 0.5 mm.
        XCTAssertEqual(stats.meanMM, 0.5, accuracy: 1e-4)
    }

    func test_medoid_picksUncorruptedFrame() {
        var samples = cleanSamples(frames: 5)
        // Frame 2 is an outlier.
        for i in samples[2].indices { samples[2][i].x += 0.01 }
        let average = FrameAggregator.robustAverage(samples)
        let medoid = FrameAggregator.medoidIndex(of: samples, against: average)
        XCTAssertNotEqual(medoid, 2, "medoid must avoid the corrupted frame")
    }

    func test_medoid_picksClosestFrame() {
        let truth = [SIMD3<Float>(0, 0, 0)]
        let samples: [[SIMD3<Float>]] = [
            [SIMD3(0.010, 0, 0)],
            [SIMD3(0.001, 0, 0)],   // closest to truth
            [SIMD3(0.005, 0, 0)],
        ]
        XCTAssertEqual(FrameAggregator.medoidIndex(of: samples, against: truth), 1)
    }
}
