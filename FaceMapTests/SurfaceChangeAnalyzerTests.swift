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
