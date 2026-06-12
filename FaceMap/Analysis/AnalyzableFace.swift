import Foundation
import simd

/// Wraps a `CapturedFace` and exposes anatomical landmarks by name.
/// Metrics consume this rather than `CapturedFace` directly so they don't need to
/// know about vertex indices.
struct AnalyzableFace {
    let captured: CapturedFace
    private let verts: [SIMD3<Float>]

    init(_ captured: CapturedFace) {
        self.captured = captured
        self.verts = captured.vertices
    }

    /// Construct directly from a vertex array. Used by tests with synthetic fixtures.
    init(vertices: [SIMD3<Float>], blendShapes: [String: Float] = [:]) {
        self.captured = CapturedFace(
            vertices: vertices,
            triangleIndices: [],
            transform: matrix_identity_float4x4,
            blendShapes: blendShapes,
            timestamp: Date()
        )
        self.verts = vertices
    }

    /// Position of a named landmark in face-local coordinates.
    /// Returns `nil` if the landmark index is unmapped or out of range.
    func position(of landmark: AnatomicalLandmark) -> SIMD3<Float>? {
        guard let idx = FaceLandmarkIndices.vertexIndex[landmark],
              idx >= 0, idx < verts.count else { return nil }
        return verts[idx]
    }

    /// Same as `position(of:)` but throws a descriptive error when the landmark is missing.
    /// Convenient inside metrics that want a single line of unwrapping.
    func require(_ landmark: AnatomicalLandmark) throws -> SIMD3<Float> {
        guard let p = position(of: landmark) else {
            throw AnalysisError.missingLandmark(landmark)
        }
        return p
    }
}

enum AnalysisError: Error, CustomStringConvertible {
    case missingLandmark(AnatomicalLandmark)

    var description: String {
        switch self {
        case .missingLandmark(let l): return "Missing landmark: \(l.rawValue)"
        }
    }
}

// MARK: - Geometry helpers used by metrics

extension SIMD3 where Scalar == Float {
    /// Euclidean distance, in face-local meters.
    func distance(to other: SIMD3<Float>) -> Double {
        Double(simd_distance(self, other))
    }
}
