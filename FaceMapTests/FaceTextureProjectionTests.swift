import XCTest
import simd
@testable import FaceMap

final class FaceTextureProjectionTests: XCTestCase {

    // Deliberately asymmetric pinhole (fx ≠ fy, off-center principal point) so any
    // axis swap or flip shows up as a numeric mismatch, not a silent pass.
    private let fx: Float = 1000
    private let fy: Float = 1100
    private let cx: Float = 700
    private let cy: Float = 500
    private let resolution = SIMD2<Float>(1440, 1080)   // landscape raw buffer (W > H)

    private var intrinsics: simd_float3x3 {
        simd_float3x3(
            SIMD3(fx, 0, 0),
            SIMD3(0, fy, 0),
            SIMD3(cx, cy, 1)
        )
    }

    private func uv(of vertex: SIMD3<Float>,
                    faceTransform: simd_float4x4 = matrix_identity_float4x4,
                    cameraTransform: simd_float4x4 = matrix_identity_float4x4,
                    intrinsics k: simd_float3x3? = nil) -> SIMD2<Float>? {
        FaceTextureProjection.photoUV(vertex: vertex,
                                      photoFaceTransform: faceTransform,
                                      cameraTransform: cameraTransform,
                                      intrinsics: k ?? intrinsics,
                                      rawImageResolution: resolution)
    }

    func test_opticalAxisPoint_withCenteredPrincipalPoint_mapsToPhotoCenter() {
        let centered = simd_float3x3(
            SIMD3(fx, 0, 0),
            SIMD3(0, fy, 0),
            SIMD3(resolution.x / 2, resolution.y / 2, 1)
        )
        let uv = uv(of: SIMD3(0, 0, -1), intrinsics: centered)
        XCTAssertNotNil(uv)
        XCTAssertEqual(uv!.x, 0.5, accuracy: 1e-6)
        XCTAssertEqual(uv!.y, 0.5, accuracy: 1e-6)
    }

    func test_opticalAxisPoint_asymmetricIntrinsics_handComputed() {
        // p_c = (0,0,-1): u_raw = cx = 700, v_raw = cy = 500.
        // x_photo = H − 500 = 580; y_photo = 700.
        let uv = uv(of: SIMD3(0, 0, -1))
        XCTAssertNotNil(uv)
        XCTAssertEqual(uv!.x, 580.0 / 1080.0, accuracy: 1e-6)
        XCTAssertEqual(uv!.y, 700.0 / 1440.0, accuracy: 1e-6)
    }

    func test_offAxisPoint_handComputed() {
        // p_c = (0.2, -0.1, -1): u_raw = 1000·0.2 + 700 = 900;
        // v_raw = 500 − 1100·(−0.1) = 610. x_photo = 1080 − 610 = 470; y_photo = 900.
        let uv = uv(of: SIMD3(0.2, -0.1, -1))
        XCTAssertNotNil(uv)
        XCTAssertEqual(uv!.x, 470.0 / 1080.0, accuracy: 1e-5)
        XCTAssertEqual(uv!.y, 900.0 / 1440.0, accuracy: 1e-5)
    }

    func test_plusXInCameraSpace_movesDownThePortraitPhoto() {
        // Locks the .oriented(.right) remap: camera +X (sensor right) is portrait DOWN.
        let center = uv(of: SIMD3(0, 0, -1))!
        let plusX = uv(of: SIMD3(0.1, 0, -1))!
        XCTAssertGreaterThan(plusX.y, center.y, "camera +X must increase portrait v (down)")
        XCTAssertEqual(plusX.x, center.x, accuracy: 1e-6, "camera +X must not change portrait u")
    }

    func test_plusYInCameraSpace_movesRightInThePortraitPhoto() {
        // Camera +Y (sensor up) → raw v decreases → x_photo = H − v_raw increases.
        let center = uv(of: SIMD3(0, 0, -1))!
        let plusY = uv(of: SIMD3(0, 0.1, -1))!
        XCTAssertGreaterThan(plusY.x, center.x, "camera +Y must increase portrait u")
        XCTAssertEqual(plusY.y, center.y, accuracy: 1e-6)
    }

    func test_behindCamera_returnsNil() {
        XCTAssertNil(uv(of: SIMD3(0, 0, 1)))
        XCTAssertNil(uv(of: SIMD3(0.3, 0.2, 0)), "point on the camera plane is not projectable")
    }

    func test_faceTransform_composesWithCameraTransform() {
        // Face frame translated 1 m in front of the camera: the face-local origin must
        // project exactly like the world point (0, 0, −1).
        var faceTransform = matrix_identity_float4x4
        faceTransform.columns.3 = SIMD4(0, 0, -1, 1)
        let viaTransform = uv(of: SIMD3(0, 0, 0), faceTransform: faceTransform)
        let direct = uv(of: SIMD3(0, 0, -1))
        XCTAssertNotNil(viaTransform)
        XCTAssertEqual(viaTransform!.x, direct!.x, accuracy: 1e-6)
        XCTAssertEqual(viaTransform!.y, direct!.y, accuracy: 1e-6)

        // Moving the CAMERA back by 1 m instead must match the face staying at −2.
        var cameraBack = matrix_identity_float4x4
        cameraBack.columns.3 = SIMD4(0, 0, 1, 1)
        let viaCamera = uv(of: SIMD3(0, 0, -1), cameraTransform: cameraBack)
        let equivalent = uv(of: SIMD3(0, 0, -2))
        XCTAssertEqual(viaCamera!.x, equivalent!.x, accuracy: 1e-6)
        XCTAssertEqual(viaCamera!.y, equivalent!.y, accuracy: 1e-6)
    }

    func test_pointOutsideFrame_returnsUVOutsideUnitRange() {
        // Steeply off-axis point: still in front of the camera, but past the frame edge.
        let uv = uv(of: SIMD3(2, 0, -1))
        XCTAssertNotNil(uv, "in-front points always project; callers clamp/fade")
        XCTAssertGreaterThan(uv!.y, 1)
    }
}
