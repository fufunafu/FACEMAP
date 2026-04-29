import Foundation
import simd
@testable import FaceMap

/// Test helper. Builds an `AnalyzableFace` whose vertex buffer is sized to hold every index
/// used by `FaceLandmarkIndices`, with specified positions placed at the appropriate indices.
enum SyntheticFace {
    static func make(_ positions: [AnatomicalLandmark: SIMD3<Float>]) -> AnalyzableFace {
        let maxIdx = (FaceLandmarkIndices.vertexIndex.values.max() ?? 0) + 1
        var verts = Array(repeating: SIMD3<Float>(repeating: 0), count: max(maxIdx, 500))
        for (landmark, p) in positions {
            if let i = FaceLandmarkIndices.vertexIndex[landmark], i < verts.count {
                verts[i] = p
            }
        }
        return AnalyzableFace(vertices: verts)
    }
}
