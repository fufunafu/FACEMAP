import Foundation
import simd

/// Pure-simd display-geometry helpers for the face mesh. No RealityKit import so
/// every function is unit-testable on the simulator.
///
/// None of these mutate or re-index the analysis mesh: landmark/region analysis is
/// index-addressed into the fixed ~1,220-vertex ARKit topology, so display code only
/// ever derives NEW arrays (centered copies, normals, inflated shells, fallback UVs).
enum FaceMeshGeometry {

    /// Area-weighted smooth vertex normals: accumulate each triangle's unnormalized
    /// cross product (proportional to its area) on its three vertices, normalize
    /// last. O(triangles) + O(vertices). Degenerate triangles are skipped; a vertex
    /// that ends up with no valid contribution falls back to +Z (out of the face).
    static func vertexNormals(positions: [SIMD3<Float>], indices: [Int16]) -> [SIMD3<Float>] {
        var normals = Array(repeating: SIMD3<Float>(repeating: 0), count: positions.count)
        var t = 0
        while t + 2 < indices.count {
            let i0 = Int(indices[t]), i1 = Int(indices[t + 1]), i2 = Int(indices[t + 2])
            t += 3
            guard i0 >= 0, i1 >= 0, i2 >= 0,
                  i0 < positions.count, i1 < positions.count, i2 < positions.count else { continue }
            let e1 = positions[i1] - positions[i0]
            let e2 = positions[i2] - positions[i0]
            let cross = simd_cross(e1, e2)
            guard simd_length_squared(cross) > 1e-12 else { continue }
            normals[i0] += cross
            normals[i1] += cross
            normals[i2] += cross
        }
        for i in normals.indices {
            let lengthSquared = simd_length_squared(normals[i])
            normals[i] = lengthSquared > 1e-12
                ? normals[i] / sqrt(lengthSquared)
                : SIMD3<Float>(0, 0, 1)
        }
        return normals
    }

    static func centroid(_ positions: [SIMD3<Float>]) -> SIMD3<Float> {
        guard !positions.isEmpty else { return .zero }
        return positions.reduce(SIMD3<Float>(repeating: 0), +) / Float(positions.count)
    }

    /// Positions displaced along their normals — used for the heatmap overlay shell
    /// so it hovers just off the skin without z-fighting.
    static func inflated(_ positions: [SIMD3<Float>],
                         normals: [SIMD3<Float>],
                         by delta: Float) -> [SIMD3<Float>] {
        zip(positions, normals).map { $0 + $1 * delta }
    }

    /// Orthographic front-projection UVs from the face-local XY bounding box.
    /// Heatmap-UV fallback for legacy records that lack ARKit's canonical UVs: the
    /// face mesh is an open front shell, so a front projection is near-injective,
    /// and a low-frequency severity heatmap is insensitive to the minor fold-over
    /// at the side edges. V is flipped (image origin top-left, +Y up in face space).
    static func planarUVs(_ positions: [SIMD3<Float>]) -> [SIMD2<Float>] {
        guard !positions.isEmpty else { return [] }
        var minP = positions[0], maxP = positions[0]
        for p in positions {
            minP = simd_min(minP, p)
            maxP = simd_max(maxP, p)
        }
        let span = maxP - minP
        let spanX = span.x > 1e-9 ? span.x : 1
        let spanY = span.y > 1e-9 ? span.y : 1
        return positions.map { p in
            SIMD2((p.x - minP.x) / spanX, 1 - (p.y - minP.y) / spanY)
        }
    }
}
