import Foundation
import CoreGraphics
import UIKit
import Vision

/// Photo-based skin-quality indicator for the FAS "Skin quality" facet.
///
/// Unlike the mesh metrics this is *not* a `FaceMetric` — it needs the clinical
/// photo, not the geometry — so `AnalysisScreen` runs it separately and merges the
/// result into the same `[MetricResult]` stream.
///
/// Pipeline: Vision face-rectangle detection → central face crop (skin, avoiding
/// hair/background) → 160×160 grayscale → two indicators:
///   • **texture** — mean high-frequency energy (|pixel − local mean|): fine lines,
///     pores, roughness raise it.
///   • **evenness** — standard deviation of the low-frequency channel: pigmentation
///     patches and shadowing raise it.
/// The reported value is the texture index; evenness goes in the notes.
///
/// THRESHOLDS ARE PROVISIONAL. The 0…0.05 target was set on a handful of reference
/// photos, not a clinical dataset — hence `confidence: 0.5`. Treat the output as a
/// longitudinal indicator (same patient, same lighting, visit over visit), not an
/// absolute score.
enum SkinQualityAnalyzer {
    static let metricId = "skin.textureEvenness"
    static let displayName = "Skin texture & evenness"
    static let target: ClosedRange<Double> = 0.0...0.05

    /// Analyze a stored clinical photo. Returns nil when the photo can't be decoded
    /// or no face is found — callers simply omit the result.
    static func evaluate(photoJPEG: Data) async -> MetricResult? {
        guard let image = UIImage(data: photoJPEG), let cg = image.cgImage else { return nil }
        guard let faceBox = await detectFaceBox(in: cg) else { return nil }

        // Central 60% of the face box: cheeks/forehead/perioral skin without
        // hairline, ears, or background.
        let inset = CGRect(
            x: faceBox.minX + faceBox.width * 0.2,
            y: faceBox.minY + faceBox.height * 0.2,
            width: faceBox.width * 0.6,
            height: faceBox.height * 0.6
        )
        guard let crop = cg.cropping(to: inset),
              let gray = grayscalePixels(crop, side: 160) else { return nil }

        let (texture, evenness) = indices(gray: gray.pixels, width: gray.width, height: gray.height)

        return MetricResult(
            metricId: metricId,
            metricName: displayName,
            domain: .skinQuality,
            value: texture,
            target: target,
            deviation: max(0, texture - target.upperBound),
            confidence: 0.5,
            regions: texture > target.upperBound
                ? [.forehead, .midfaceL, .midfaceR, .perioral]
                : [],
            notes: String(format: "texture %.3f · evenness %.3f (photo-based indicator)",
                          texture, evenness)
        )
    }

    // MARK: - Vision

    private static func detectFaceBox(in cg: CGImage) async -> CGRect? {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, _ in
                guard let face = (request.results as? [VNFaceObservation])?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                // Vision returns a normalized rect with origin at bottom-left;
                // convert to CGImage pixel coordinates (origin top-left).
                let b = face.boundingBox
                let w = CGFloat(cg.width), h = CGFloat(cg.height)
                continuation.resume(returning: CGRect(
                    x: b.minX * w,
                    y: (1 - b.maxY) * h,
                    width: b.width * w,
                    height: b.height * h
                ))
            }
            let handler = VNImageRequestHandler(cgImage: cg)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Pixel extraction

    /// Downscale to at most `side`×`side` 8-bit grayscale and return 0…1 floats.
    static func grayscalePixels(_ cg: CGImage, side: Int) -> (pixels: [Float], width: Int, height: Int)? {
        let scale = min(1, CGFloat(side) / CGFloat(max(cg.width, cg.height)))
        let w = max(8, Int(CGFloat(cg.width) * scale))
        let h = max(8, Int(CGFloat(cg.height) * scale))
        var bytes = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(
            data: &bytes, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (bytes.map { Float($0) / 255.0 }, w, h)
    }

    // MARK: - Pure indicator math (unit-tested)

    /// Texture = mean |pixel − 5×5 local mean| (high-frequency energy).
    /// Evenness = standard deviation of the 5×5 local-mean image (low-frequency).
    static func indices(gray: [Float], width: Int, height: Int) -> (texture: Double, evenness: Double) {
        guard width > 4, height > 4, gray.count == width * height else { return (0, 0) }
        let radius = 2
        var low = [Float](repeating: 0, count: gray.count)

        for y in 0..<height {
            for x in 0..<width {
                var sum: Float = 0
                var n: Float = 0
                for dy in -radius...radius {
                    let yy = y + dy
                    guard yy >= 0, yy < height else { continue }
                    for dx in -radius...radius {
                        let xx = x + dx
                        guard xx >= 0, xx < width else { continue }
                        sum += gray[yy * width + xx]
                        n += 1
                    }
                }
                low[y * width + x] = sum / n
            }
        }

        var highEnergy: Double = 0
        var lowSum: Double = 0
        for i in 0..<gray.count {
            highEnergy += Double(abs(gray[i] - low[i]))
            lowSum += Double(low[i])
        }
        let count = Double(gray.count)
        let texture = highEnergy / count

        let lowMean = lowSum / count
        var varianceSum: Double = 0
        for v in low {
            let d = Double(v) - lowMean
            varianceSum += d * d
        }
        let evenness = (varianceSum / count).squareRoot()

        return (texture, evenness)
    }
}
