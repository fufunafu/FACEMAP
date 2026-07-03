import XCTest
import simd
@testable import FaceMap

final class FaceMeshGeometryTests: XCTestCase {

    // MARK: Normals

    func test_singleTriangle_normalIsFaceNormal() {
        // CCW triangle in the XY plane → +Z normal on all three vertices.
        let positions: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(0, 1, 0)]
        let normals = FaceMeshGeometry.vertexNormals(positions: positions, indices: [0, 1, 2])
        for n in normals {
            XCTAssertEqual(n.x, 0, accuracy: 1e-6)
            XCTAssertEqual(n.y, 0, accuracy: 1e-6)
            XCTAssertEqual(n.z, 1, accuracy: 1e-6)
        }
    }

    func test_areaWeighting_largeTriangleDominates() {
        // Vertex 0 is shared by a big +Z triangle (area 50) and a small +X triangle
        // (area 0.005): the blended normal must lean overwhelmingly toward +Z.
        let positions: [SIMD3<Float>] = [
            SIMD3(0, 0, 0),                       // shared
            SIMD3(10, 0, 0), SIMD3(0, 10, 0),     // big triangle in XY plane → +Z
            SIMD3(0, 0.1, 0), SIMD3(0, 0, 0.1),   // small triangle in YZ plane → +X
        ]
        let normals = FaceMeshGeometry.vertexNormals(positions: positions,
                                                     indices: [0, 1, 2, 0, 3, 4])
        let shared = normals[0]
        XCTAssertGreaterThan(shared.z, 0.99, "area weighting must favor the big triangle")
        XCTAssertGreaterThan(shared.x, 0, "small triangle still contributes")
        XCTAssertEqual(simd_length(shared), 1, accuracy: 1e-5)
    }

    func test_degenerateTriangle_isSkipped_andOrphanFallsBackPlusZ() {
        // All three vertices collinear → zero-area triangle; its vertices get +Z.
        let positions: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(2, 0, 0)]
        let normals = FaceMeshGeometry.vertexNormals(positions: positions, indices: [0, 1, 2])
        for n in normals {
            XCTAssertEqual(n, SIMD3(0, 0, 1))
        }
    }

    func test_outOfRangeIndices_areIgnored() {
        let positions: [SIMD3<Float>] = [SIMD3(0, 0, 0), SIMD3(1, 0, 0), SIMD3(0, 1, 0)]
        let normals = FaceMeshGeometry.vertexNormals(positions: positions,
                                                     indices: [0, 1, 9])
        XCTAssertEqual(normals.count, 3)
        for n in normals {
            XCTAssertFalse(n.x.isNaN)
            XCTAssertEqual(simd_length(n), 1, accuracy: 1e-5)
        }
    }

    /// Face-like open dome: a 20×20 grid of vertices bulged along +Z, fully
    /// triangulated — the same shape class as the ARKit front shell.
    private func domeMesh() -> (positions: [SIMD3<Float>], indices: [Int16]) {
        let n = 20
        var positions: [SIMD3<Float>] = []
        for row in 0..<n {
            for col in 0..<n {
                let x = Float(col) / Float(n - 1) * 0.14 - 0.07
                let y = Float(row) / Float(n - 1) * 0.18 - 0.09
                let z = 0.06 * (1 - (x * x + y * y) / 0.02)
                positions.append(SIMD3(x, y, z))
            }
        }
        var indices: [Int16] = []
        for row in 0..<(n - 1) {
            for col in 0..<(n - 1) {
                let a = Int16(row * n + col), b = a + 1
                let c = Int16((row + 1) * n + col), d = c + 1
                indices.append(contentsOf: [a, b, c, b, d, c])
            }
        }
        return (positions, indices)
    }

    func test_domeMesh_producesUnitNormals_noNaN() {
        let (positions, indices) = domeMesh()
        let normals = FaceMeshGeometry.vertexNormals(positions: positions, indices: indices)
        XCTAssertEqual(normals.count, positions.count)
        for n in normals {
            XCTAssertFalse(n.x.isNaN || n.y.isNaN || n.z.isNaN)
            XCTAssertEqual(simd_length(n), 1, accuracy: 1e-4)
        }
        // The dome bulges toward +Z, so the apex normal must point out of the face.
        let apex = normals[positions.count / 2]
        XCTAssertGreaterThan(apex.z, 0.5)
    }

    // MARK: Centroid / inflation

    func test_centroid() {
        let c = FaceMeshGeometry.centroid([SIMD3(0, 0, 0), SIMD3(2, 4, 6)])
        XCTAssertEqual(c, SIMD3(1, 2, 3))
        XCTAssertEqual(FaceMeshGeometry.centroid([]), .zero)
    }

    func test_inflated_movesAlongNormals() {
        let inflated = FaceMeshGeometry.inflated([SIMD3(1, 1, 1)],
                                                 normals: [SIMD3(0, 0, 1)],
                                                 by: 0.5)
        XCTAssertEqual(inflated[0], SIMD3(1, 1, 1.5))
    }

    // MARK: Planar UVs

    func test_planarUVs_cornersMapToUnitCorners() {
        // A flat quad spanning x ∈ [−1, 1], y ∈ [−1, 1].
        let positions: [SIMD3<Float>] = [
            SIMD3(-1, -1, 0), SIMD3(1, -1, 0), SIMD3(1, 1, 0), SIMD3(-1, 1, 0),
        ]
        let uvs = FaceMeshGeometry.planarUVs(positions)
        // v flipped: +Y (top of face) → v = 0.
        XCTAssertEqual(uvs[0], SIMD2(0, 1))   // bottom-left
        XCTAssertEqual(uvs[1], SIMD2(1, 1))   // bottom-right
        XCTAssertEqual(uvs[2], SIMD2(1, 0))   // top-right
        XCTAssertEqual(uvs[3], SIMD2(0, 0))   // top-left
    }

    func test_planarUVs_allWithinUnitRange_onDome() {
        for uv in FaceMeshGeometry.planarUVs(domeMesh().positions) {
            XCTAssertGreaterThanOrEqual(uv.x, 0); XCTAssertLessThanOrEqual(uv.x, 1)
            XCTAssertGreaterThanOrEqual(uv.y, 0); XCTAssertLessThanOrEqual(uv.y, 1)
        }
    }
}
