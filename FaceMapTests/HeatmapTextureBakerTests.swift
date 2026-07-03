import XCTest
import simd
@testable import FaceMap

final class HeatmapTextureBakerTests: XCTestCase {

    // MARK: UV → texel convention

    func test_texelConvention_vZeroIsBottomRow() {
        let bottom = HeatmapTextureBaker.texelXY(u: 0, v: 0, size: 100)
        XCTAssertEqual(bottom.x, 0)
        XCTAssertEqual(bottom.y, 99, "v=0 must map to the bottom row (USD/GL convention)")
        let top = HeatmapTextureBaker.texelXY(u: 1, v: 1, size: 100)
        XCTAssertEqual(top.x, 99)
        XCTAssertEqual(top.y, 0)
    }

    // MARK: Raster interpolation

    func test_rgbTriangle_barycenterInterpolatesEvenly() {
        var buffer = RasterBuffer(size: 64)
        // Large triangle; opaque red/green/blue corners.
        let p0: (x: Float, y: Float) = (2, 2)
        let p1: (x: Float, y: Float) = (60, 2)
        let p2: (x: Float, y: Float) = (2, 60)
        buffer.fillTriangle(p0: p0, p1: p1, p2: p2,
                            c0: SIMD4(1, 0, 0, 1), c1: SIMD4(0, 1, 0, 1), c2: SIMD4(0, 0, 1, 1))

        let cx = Int((p0.x + p1.x + p2.x) / 3), cy = Int((p0.y + p1.y + p2.y) / 3)
        let center = buffer.rgba(x: cx, y: cy)
        XCTAssertEqual(center.x, 1.0 / 3.0, accuracy: 0.05)
        XCTAssertEqual(center.y, 1.0 / 3.0, accuracy: 0.05)
        XCTAssertEqual(center.z, 1.0 / 3.0, accuracy: 0.05)
        XCTAssertEqual(center.w, 1.0, accuracy: 0.01)

        // Near-corner texel matches its vertex color.
        let nearRed = buffer.rgba(x: 4, y: 4)
        XCTAssertGreaterThan(nearRed.x, 0.8)

        // Far outside the triangle stays untouched (alpha 0).
        XCTAssertEqual(buffer.rgba(x: 62, y: 62).w, 0)
    }

    func test_dilation_extendsEdgesByOneTexel() {
        var buffer = RasterBuffer(size: 16)
        buffer.write(x: 8, y: 8, rgba: SIMD4(1, 0, 0, 1))
        buffer.dilate()
        XCTAssertGreaterThan(buffer.rgba(x: 7, y: 8).w, 0.9, "neighbor inherits the covered texel")
        XCTAssertGreaterThan(buffer.rgba(x: 9, y: 9).w, 0.9)
        XCTAssertEqual(buffer.rgba(x: 5, y: 8).w, 0, "two texels away stays empty after one pass")
    }

    // MARK: End-to-end bake

    /// UVs sized to cover every region index, spread on a grid so triangles are valid.
    private func syntheticUVs(count: Int) -> [SIMD2<Float>] {
        (0..<count).map { i in
            SIMD2(Float(i % 40) / 39, Float(i / 40) / Float(max(count / 40, 1)))
        }
    }

    func test_bake_flaggedRegion_producesTexture_unflaggedProducesNil() {
        let region = FacialRegion.allCases.first { FaceLandmarkIndices.regionVertices[$0]?.count ?? 0 >= 3 }!
        let indices = FaceLandmarkIndices.regionVertices[region]!
        let vertexCount = (FaceLandmarkIndices.regionVertices.values.flatMap { $0 }.max() ?? 0) + 1
        let uvs = syntheticUVs(count: vertexCount)
        let triangle: [Int16] = indices.prefix(3).map(Int16.init)

        // Flagged → a texture is produced.
        let flagged = HeatmapTextureBaker.bake(uvs: uvs,
                                               triangleIndices: triangle,
                                               regionSeverity: [region: .significant],
                                               regionDomain: [region: .symmetry],
                                               size: 64)
        XCTAssertNotNil(flagged)
        XCTAssertEqual(flagged?.width, 64)

        // All-normal severities → nothing to paint → nil (overlay stays hidden).
        let normal = HeatmapTextureBaker.bake(uvs: uvs,
                                              triangleIndices: triangle,
                                              regionSeverity: [region: .normal],
                                              regionDomain: [region: .symmetry],
                                              size: 64)
        XCTAssertNil(normal)

        // No flags at all → nil.
        let empty = HeatmapTextureBaker.bake(uvs: uvs,
                                             triangleIndices: triangle,
                                             regionSeverity: [:],
                                             regionDomain: [:],
                                             size: 64)
        XCTAssertNil(empty)
    }
}
