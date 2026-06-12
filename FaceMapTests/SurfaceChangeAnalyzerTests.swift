import XCTest
import simd
@testable import FaceMap

final class SurfaceChangeAnalyzerTests: XCTestCase {
    /// Vertex buffer big enough for every default landmark/region index, with
    /// deterministic non-zero positions so offsets are distinguishable.
    private func baseVertices() -> [SIMD3<Float>] {
        (0..<500).map { i in
            SIMD3<Float>(Float(i % 7) * 0.01, Float(i % 11) * 0.01, Float(i % 5) * 0.01)
        }
    }

    private func face(_ vertices: [SIMD3<Float>]) -> CapturedFace {
        CapturedFace(
            vertices: vertices,
            triangleIndices: [],
            transform: matrix_identity_float4x4,
            blendShapes: [:],
            timestamp: Date()
        )
    }

    func test_identicalMeshes_reportZeroEverywhere() {
        let v = baseVertices()
        let changes = SurfaceChangeAnalyzer.regionChanges(from: face(v), to: face(v))
        XCTAssertFalse(changes.isEmpty)
        for c in changes {
            XCTAssertEqual(c.deltaZMeters, 0, accuracy: 1e-9, "\(c.region) should be unchanged")
            XCTAssertFalse(c.exceedsNoiseFloor)
        }
    }

    func test_regionalGain_isReportedForThatRegionOnly() {
        let before = baseVertices()
        var after = before
        // +1 mm anterior projection on every midfaceL vertex.
        let midfaceL = FaceLandmarkIndices.regionVertices[.midfaceL] ?? []
        XCTAssertFalse(midfaceL.isEmpty)
        for i in midfaceL { after[i].z += 0.001 }

        let changes = SurfaceChangeAnalyzer.regionChanges(from: face(before), to: face(after))
        let byRegion = Dictionary(uniqueKeysWithValues: changes.map { ($0.region, $0) })

        let gained = try! XCTUnwrap(byRegion[.midfaceL])
        XCTAssertEqual(gained.deltaZMeters, 0.001, accuracy: 1e-6)
        XCTAssertTrue(gained.exceedsNoiseFloor)
        // Largest change sorts first.
        XCTAssertEqual(changes.first?.region, .midfaceL)
        // The contralateral side (no shared vertices) is untouched.
        let other = try! XCTUnwrap(byRegion[.midfaceR])
        XCTAssertEqual(other.deltaZMeters, 0, accuracy: 1e-6)
    }

    func test_volumeLoss_isNegative() {
        let before = baseVertices()
        var after = before
        let chin = FaceLandmarkIndices.regionVertices[.chin] ?? []
        for i in chin { after[i].z -= 0.002 }

        let changes = SurfaceChangeAnalyzer.regionChanges(from: face(before), to: face(after))
        let chinChange = changes.first { $0.region == .chin }
        XCTAssertEqual(chinChange?.deltaZMeters ?? 0, -0.002, accuracy: 1e-6)
    }

    func test_globalCaptureOffset_isCancelledByStableLandmarks() {
        let before = baseVertices()
        // Whole mesh shifted 5 mm forward — a session-to-session anchor offset,
        // not tissue change. The bony-landmark alignment must cancel it.
        let after = before.map { SIMD3<Float>($0.x, $0.y, $0.z + 0.005) }

        let changes = SurfaceChangeAnalyzer.regionChanges(from: face(before), to: face(after))
        for c in changes {
            XCTAssertEqual(c.deltaZMeters, 0, accuracy: 1e-6, "\(c.region) offset not cancelled")
        }
    }

    func test_offsetPlusRealChange_reportsOnlyTheRealChange() {
        let before = baseVertices()
        var after = before.map { SIMD3<Float>($0.x, $0.y, $0.z + 0.005) }
        let midfaceR = FaceLandmarkIndices.regionVertices[.midfaceR] ?? []
        for i in midfaceR { after[i].z += 0.001 }

        let changes = SurfaceChangeAnalyzer.regionChanges(from: face(before), to: face(after))
        let byRegion = Dictionary(uniqueKeysWithValues: changes.map { ($0.region, $0) })
        XCTAssertEqual(byRegion[.midfaceR]?.deltaZMeters ?? 0, 0.001, accuracy: 1e-6)
        XCTAssertEqual(byRegion[.midfaceL]?.deltaZMeters ?? 0, 0, accuracy: 1e-6)
    }

    func test_topologyMismatch_returnsEmpty() {
        let a = baseVertices()
        let b = Array(a.prefix(100))
        XCTAssertTrue(SurfaceChangeAnalyzer.regionChanges(from: face(a), to: face(b)).isEmpty)
        XCTAssertTrue(SurfaceChangeAnalyzer.regionChanges(from: face([]), to: face([])).isEmpty)
    }
}

// MARK: - Noise floor pinning

/// The ±0.3 mm noise floor is quoted in the Compare UI and the PDF report — pin the
/// constant and its boundary semantics so a casual edit can't silently change what
/// "real change" means clinically.
final class SurfaceChangeNoiseFloorTests: XCTestCase {
    func test_noiseFloor_isPinnedAtZeroPointThreeMillimeters() {
        XCTAssertEqual(SurfaceChangeAnalyzer.noiseFloorMeters, 0.0003)
    }

    func test_exceedsNoiseFloor_boundaryAtExactlyZeroPointThreeMillimeters() {
        // `>=` semantics: exactly 0.3 mm counts as exceeding, in either direction.
        XCTAssertTrue(RegionChange(region: .chin, deltaZMeters: 0.0003, vertexCount: 4).exceedsNoiseFloor)
        XCTAssertTrue(RegionChange(region: .chin, deltaZMeters: -0.0003, vertexCount: 4).exceedsNoiseFloor)

        // Just inside the floor — capture noise, not tissue.
        XCTAssertFalse(RegionChange(region: .chin, deltaZMeters: 0.000299, vertexCount: 4).exceedsNoiseFloor)
        XCTAssertFalse(RegionChange(region: .chin, deltaZMeters: -0.000299, vertexCount: 4).exceedsNoiseFloor)
        XCTAssertFalse(RegionChange(region: .chin, deltaZMeters: 0, vertexCount: 4).exceedsNoiseFloor)

        // Just past it.
        XCTAssertTrue(RegionChange(region: .chin, deltaZMeters: 0.000301, vertexCount: 4).exceedsNoiseFloor)
    }
}

// MARK: - CapturePose window math

/// The coached-capture flow auto-fires when the live yaw enters a pose's ±5° window;
/// these tests pin the window boundaries and the sign conventions.
final class CapturePoseWindowTests: XCTestCase {
    func test_targetYaws_followHeadPoseSignConvention() {
        // Yaw > 0 = head turned to the camera's right. obliqueL (shows the patient's
        // left side, patient turned to their right) is therefore negative.
        XCTAssertEqual(CapturePose.frontal.targetYawDegrees, 0)
        XCTAssertEqual(CapturePose.obliqueL.targetYawDegrees, -30)
        XCTAssertEqual(CapturePose.obliqueR.targetYawDegrees, 30)
        XCTAssertEqual(CapturePose.frontal.yawToleranceDegrees, 5)
    }

    func test_contains_atExactWindowBoundaries() {
        // ±5° inclusive around each target.
        XCTAssertTrue(CapturePose.frontal.contains(yawDegrees: 5))
        XCTAssertTrue(CapturePose.frontal.contains(yawDegrees: -5))
        XCTAssertFalse(CapturePose.frontal.contains(yawDegrees: 5.001))
        XCTAssertFalse(CapturePose.frontal.contains(yawDegrees: -5.001))

        XCTAssertTrue(CapturePose.obliqueL.contains(yawDegrees: -25))
        XCTAssertTrue(CapturePose.obliqueL.contains(yawDegrees: -35))
        XCTAssertFalse(CapturePose.obliqueL.contains(yawDegrees: -24.999))
        XCTAssertFalse(CapturePose.obliqueL.contains(yawDegrees: -35.001))

        XCTAssertTrue(CapturePose.obliqueR.contains(yawDegrees: 25))
        XCTAssertTrue(CapturePose.obliqueR.contains(yawDegrees: 35))
        XCTAssertFalse(CapturePose.obliqueR.contains(yawDegrees: 24.999))
        XCTAssertFalse(CapturePose.obliqueR.contains(yawDegrees: 35.001))
    }

    func test_windows_doNotOverlap() {
        // A yaw can satisfy at most one pose — the coach can never auto-fire ambiguously.
        for yaw in stride(from: -40.0, through: 40.0, by: 0.5) {
            let matching = CapturePose.allCases.filter { $0.contains(yawDegrees: yaw) }
            XCTAssertLessThanOrEqual(matching.count, 1, "yaw \(yaw)° matched \(matching)")
        }
    }

    func test_yawError_signConvention() {
        // Positive error = patient needs to turn further toward camera-right.
        XCTAssertEqual(CapturePose.frontal.yawError(currentDegrees: -10), 10)
        XCTAssertEqual(CapturePose.frontal.yawError(currentDegrees: 10), -10)
        XCTAssertEqual(CapturePose.obliqueR.yawError(currentDegrees: 20), 10)
        XCTAssertEqual(CapturePose.obliqueR.yawError(currentDegrees: 40), -10)
        XCTAssertEqual(CapturePose.obliqueL.yawError(currentDegrees: 0), -30)
        XCTAssertEqual(CapturePose.obliqueL.yawError(currentDegrees: -30), 0)
    }
}

// MARK: - HeadPose Euler decomposition

final class HeadPoseDecompositionTests: XCTestCase {
    func test_identityTransform_decomposesToZero_andIsLevel() {
        let pose = HeadPose.from(transform: matrix_identity_float4x4)
        XCTAssertEqual(pose.pitchDegrees, 0, accuracy: 1e-6)
        XCTAssertEqual(pose.yawDegrees, 0, accuracy: 1e-6)
        XCTAssertEqual(pose.rollDegrees, 0, accuracy: 1e-6)
        XCTAssertTrue(pose.isLevel())
        XCTAssertEqual(pose.maxAbsoluteDegrees, 0, accuracy: 1e-6)
    }

    func test_thirtyDegreeYaw_decomposesToPlusThirty() {
        // +30° about world +Y = head turned to the camera's right.
        let t = simd_float4x4(simd_quatf(angle: .pi / 6, axis: SIMD3<Float>(0, 1, 0)))
        let pose = HeadPose.from(transform: t)

        XCTAssertEqual(pose.yawDegrees, 30, accuracy: 0.001)
        XCTAssertEqual(pose.pitchDegrees, 0, accuracy: 0.001)
        XCTAssertEqual(pose.rollDegrees, 0, accuracy: 0.001)
        XCTAssertFalse(pose.isLevel())
        // A clean +30° yaw is exactly the obliqueR capture target.
        XCTAssertTrue(CapturePose.obliqueR.contains(yawDegrees: pose.yawDegrees))
    }

    func test_minusThirtyDegreeYaw_matchesObliqueLWindow() {
        let t = simd_float4x4(simd_quatf(angle: -.pi / 6, axis: SIMD3<Float>(0, 1, 0)))
        let pose = HeadPose.from(transform: t)

        XCTAssertEqual(pose.yawDegrees, -30, accuracy: 0.001)
        XCTAssertTrue(CapturePose.obliqueL.contains(yawDegrees: pose.yawDegrees))
        XCTAssertFalse(CapturePose.obliqueR.contains(yawDegrees: pose.yawDegrees))
    }
}
