import XCTest
import simd
@testable import FaceMap

final class PhotoUVProjectorTests: XCTestCase {

    /// Camera at origin (identity), face frame at identity, symmetric pinhole.
    private func captureWithProjectionData(vertices: [SIMD3<Float>]) -> CapturedFace {
        CapturedFace(vertices: vertices,
                     triangleIndices: [],
                     transform: matrix_identity_float4x4,
                     blendShapes: [:],
                     timestamp: Date(timeIntervalSinceReferenceDate: 0),
                     textureCoordinates: vertices.map { _ in SIMD2(0.5, 0.5) },
                     cameraIntrinsics: simd_float3x3(SIMD3(1000, 0, 0),
                                                     SIMD3(0, 1000, 0),
                                                     SIMD3(720, 540, 1)),
                     cameraImageResolution: SIMD2(1440, 1080),
                     cameraTransform: matrix_identity_float4x4,
                     photoFaceTransform: matrix_identity_float4x4)
    }

    func test_legacyCapture_returnsNil() {
        let face = CapturedFace(vertices: [SIMD3(0, 0, -1)],
                                triangleIndices: [],
                                transform: matrix_identity_float4x4,
                                blendShapes: [:],
                                timestamp: Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertNil(PhotoUVProjector.project(vertices: face.vertices,
                                              normals: [SIMD3(0, 0, 1)],
                                              face: face))
    }

    func test_visibility_facingCameraIsOne_backfacingIsZero() {
        let vertices: [SIMD3<Float>] = [SIMD3(0, 0, -1), SIMD3(0, 0, -1)]
        let face = captureWithProjectionData(vertices: vertices)
        // Vertex at z = −1; camera at origin → toCamera = +Z.
        let projection = PhotoUVProjector.project(vertices: vertices,
                                                  normals: [SIMD3(0, 0, 1), SIMD3(0, 0, -1)],
                                                  face: face)
        XCTAssertNotNil(projection)
        XCTAssertEqual(projection!.visibility[0], 1, accuracy: 1e-5)
        XCTAssertEqual(projection!.visibility[1], 0, accuracy: 1e-5)
        // On-axis vertex with a centered principal point → photo center.
        XCTAssertEqual(projection!.imageUV[0].x, 0.5, accuracy: 1e-5)
        XCTAssertEqual(projection!.imageUV[0].y, 0.5, accuracy: 1e-5)
    }

    func test_behindCamera_marksNaN_andZeroVisibility() {
        let vertices: [SIMD3<Float>] = [SIMD3(0, 0, 1)]
        let face = captureWithProjectionData(vertices: vertices)
        let projection = PhotoUVProjector.project(vertices: vertices,
                                                  normals: [SIMD3(0, 0, 1)],
                                                  face: face)
        XCTAssertNotNil(projection)
        XCTAssertTrue(projection!.imageUV[0].x.isNaN)
        XCTAssertEqual(projection!.visibility[0], 0)
    }

    // MARK: Image sampling

    func test_imageSampler_bilinear() throws {
        // 2×2 image: white top-left, black elsewhere.
        var buffer = RasterBuffer(size: 2)
        buffer.write(x: 0, y: 0, rgba: SIMD4(1, 1, 1, 1))
        buffer.write(x: 1, y: 0, rgba: SIMD4(0, 0, 0, 1))
        buffer.write(x: 0, y: 1, rgba: SIMD4(0, 0, 0, 1))
        buffer.write(x: 1, y: 1, rgba: SIMD4(0, 0, 0, 1))
        let image = try XCTUnwrap(buffer.makeImage())
        let sampler = try XCTUnwrap(ImageSampler(image))

        // (0,0) = top-left in photo UV convention.
        XCTAssertEqual(sampler.bilinear(u: 0, v: 0).x, 1, accuracy: 0.02)
        XCTAssertEqual(sampler.bilinear(u: 1, v: 1).x, 0, accuracy: 0.02)
        // Center blends 4 texels: 1/4 white.
        XCTAssertEqual(sampler.bilinear(u: 0.5, v: 0.5).x, 0.25, accuracy: 0.05)
    }

    // MARK: Atlas bake smoke test

    func test_bakeAtlas_producesImage_withNeutralFallbackForBackfacing() throws {
        // A photo that is uniformly bright red.
        var photoBuffer = RasterBuffer(size: 4)
        for y in 0..<4 { for x in 0..<4 { photoBuffer.write(x: x, y: y, rgba: SIMD4(1, 0, 0, 1)) } }
        let photo = try XCTUnwrap(photoBuffer.makeImage())

        // One visible triangle spanning most of the atlas.
        let canonicalUVs: [SIMD2<Float>] = [SIMD2(0.1, 0.1), SIMD2(0.9, 0.1), SIMD2(0.1, 0.9)]
        let projection = PhotoUVProjector.PhotoProjection(
            imageUV: [SIMD2(0.5, 0.5), SIMD2(0.6, 0.5), SIMD2(0.5, 0.6)],
            visibility: [1, 1, 1]
        )
        let atlas = try XCTUnwrap(PhotoTextureBaker.bakeAtlas(photo: photo,
                                                              canonicalUVs: canonicalUVs,
                                                              triangleIndices: [0, 1, 2],
                                                              projection: projection,
                                                              size: 64))
        // Sample inside the triangle: fully visible → photo red, not neutral grey.
        let sampler = try XCTUnwrap(ImageSampler(atlas))
        let inside = sampler.bilinear(u: 0.3, v: 1 - 0.3)   // atlas v=0 is bottom (texelXY)
        XCTAssertGreaterThan(inside.x, 0.8)
        XCTAssertLessThan(inside.y, 0.3)

        // Backfacing triangle bakes to the neutral tint instead of smearing photo pixels.
        let backfacing = PhotoUVProjector.PhotoProjection(
            imageUV: [SIMD2(0.5, 0.5), SIMD2(0.6, 0.5), SIMD2(0.5, 0.6)],
            visibility: [0, 0, 0]
        )
        let clayAtlas = try XCTUnwrap(PhotoTextureBaker.bakeAtlas(photo: photo,
                                                                  canonicalUVs: canonicalUVs,
                                                                  triangleIndices: [0, 1, 2],
                                                                  projection: backfacing,
                                                                  size: 64))
        let claySampler = try XCTUnwrap(ImageSampler(clayAtlas))
        let clay = claySampler.bilinear(u: 0.3, v: 1 - 0.3)
        XCTAssertEqual(clay.x, MeshPalette.neutral.x, accuracy: 0.03)
        XCTAssertEqual(clay.z, MeshPalette.neutral.z, accuracy: 0.03)
    }
}
