import XCTest
@testable import FaceMap

final class SkinQualityAnalyzerTests: XCTestCase {
    private let w = 64
    private let h = 64

    /// Uniform mid-gray field — zero texture, zero unevenness.
    func test_uniformField_isFlat() {
        let gray = [Float](repeating: 0.5, count: w * h)
        let (texture, evenness) = SkinQualityAnalyzer.indices(gray: gray, width: w, height: h)
        XCTAssertEqual(texture, 0, accuracy: 1e-9)
        XCTAssertEqual(evenness, 0, accuracy: 1e-9)
    }

    /// Checkerboard = pure high-frequency content: texture high, evenness near zero
    /// (the local means converge to 0.5 everywhere away from edges).
    func test_checkerboard_raisesTextureNotEvenness() {
        var gray = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                gray[y * w + x] = (x + y) % 2 == 0 ? 1.0 : 0.0
            }
        }
        let (texture, evenness) = SkinQualityAnalyzer.indices(gray: gray, width: w, height: h)
        XCTAssertGreaterThan(texture, 0.2)
        XCTAssertLessThan(evenness, 0.1)
    }

    /// Smooth left-to-right gradient = pure low-frequency content: evenness high,
    /// texture near zero.
    func test_gradient_raisesEvennessNotTexture() {
        var gray = [Float](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                gray[y * w + x] = Float(x) / Float(w - 1)
            }
        }
        let (texture, evenness) = SkinQualityAnalyzer.indices(gray: gray, width: w, height: h)
        XCTAssertLessThan(texture, 0.02)
        XCTAssertGreaterThan(evenness, 0.1)
    }

    /// Noisier field scores strictly higher texture than a smoother one — the ordering
    /// that makes the indicator usable longitudinally.
    func test_noisier_beatsSmoother() {
        func noisyField(amplitude: Float) -> [Float] {
            // Deterministic pseudo-noise (no RNG in tests for reproducibility).
            (0..<(w * h)).map { i in
                0.5 + amplitude * (Float((i * 31 + 17) % 97) / 97.0 - 0.5)
            }
        }
        let (smooth, _) = SkinQualityAnalyzer.indices(gray: noisyField(amplitude: 0.05), width: w, height: h)
        let (rough, _) = SkinQualityAnalyzer.indices(gray: noisyField(amplitude: 0.4), width: w, height: h)
        XCTAssertGreaterThan(rough, smooth)
    }

    func test_degenerateInput_returnsZero() {
        let (texture, evenness) = SkinQualityAnalyzer.indices(gray: [0.5], width: 1, height: 1)
        XCTAssertEqual(texture, 0)
        XCTAssertEqual(evenness, 0)
    }

    /// Garbage JPEG data → nil, never a bogus result.
    func test_undecodablePhoto_returnsNil() async {
        let result = await SkinQualityAnalyzer.evaluate(photoJPEG: Data([0x00, 0x01, 0x02]))
        XCTAssertNil(result)
    }
}
