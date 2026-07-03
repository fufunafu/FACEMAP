import Foundation
import simd

/// Pure per-vertex aggregation of buffered capture frames. Kept free of ARKit types
/// so it is fully unit-testable on the simulator.
enum FrameAggregator {

    /// Per-vertex, per-component MEDIAN across samples. All samples must share the
    /// same vertex count (callers filter mixed-topology frames out first).
    ///
    /// Median rather than mean: with ≤10 samples the median has a 50% breakdown
    /// point, so up to 4 outlier frames (blink burst, micro-twitch, momentary
    /// tracking glitch) leave the result untouched, where a mean would smear them in.
    /// The efficiency penalty under clean symmetric noise is irrelevant at these
    /// magnitudes (10-frame TrueDepth jitter sits well under the 0.3 mm analyzer
    /// noise floor either way). ~1220 × 3 ten-element medians is well under 1 ms.
    static func robustAverage(_ samples: [[SIMD3<Float>]]) -> [SIMD3<Float>] {
        guard let first = samples.first else { return [] }
        guard samples.count > 1 else { return first }
        let n = first.count
        var out = Array(repeating: SIMD3<Float>(repeating: 0), count: n)
        var scratch = [Float](repeating: 0, count: samples.count)
        for i in 0..<n {
            for axis in 0..<3 {
                for (s, sample) in samples.enumerated() { scratch[s] = sample[i][axis] }
                out[i][axis] = median(&scratch)
            }
        }
        return out
    }

    /// Temporal-noise statistics: per-vertex standard deviation across samples
    /// (norm of the three per-component stddevs), reported in millimeters as
    /// (mean over vertices, max over vertices). Returns (0, 0) for < 2 samples.
    static func jitterStats(_ samples: [[SIMD3<Float>]]) -> (meanMM: Float, maxMM: Float) {
        guard samples.count > 1, let first = samples.first else { return (0, 0) }
        let n = first.count
        guard n > 0 else { return (0, 0) }
        let count = Float(samples.count)
        var sumSigma: Float = 0
        var maxSigma: Float = 0
        for i in 0..<n {
            var mean = SIMD3<Float>(repeating: 0)
            for sample in samples { mean += sample[i] }
            mean /= count
            var variance = SIMD3<Float>(repeating: 0)
            for sample in samples {
                let d = sample[i] - mean
                variance += d * d
            }
            variance /= count
            let sigma = sqrt(variance.x + variance.y + variance.z)
            sumSigma += sigma
            maxSigma = max(maxSigma, sigma)
        }
        let toMM: Float = 1000
        return (sumSigma / Float(n) * toMM, maxSigma * toMM)
    }

    /// Index of the sample geometrically closest (mean squared distance) to `average`.
    /// Used to pick the transform/blendshape frame that best matches the aggregated
    /// mesh: rigid transforms don't average componentwise, and blendshapes must stay
    /// a coherent single-frame snapshot, so both come from the medoid frame.
    static func medoidIndex(of samples: [[SIMD3<Float>]], against average: [SIMD3<Float>]) -> Int {
        var bestIndex = 0
        var bestScore = Float.greatestFiniteMagnitude
        for (s, sample) in samples.enumerated() {
            var score: Float = 0
            let n = min(sample.count, average.count)
            for i in 0..<n {
                score += simd_length_squared(sample[i] - average[i])
            }
            if score < bestScore {
                bestScore = score
                bestIndex = s
            }
        }
        return bestIndex
    }

    /// Median of `values` (mutated in place by sorting). Even counts return the mean
    /// of the two central elements.
    private static func median(_ values: inout [Float]) -> Float {
        values.sort()
        let mid = values.count / 2
        if values.count % 2 == 1 { return values[mid] }
        return (values[mid - 1] + values[mid]) / 2
    }
}
