import XCTest
import SwiftData
import simd
@testable import FaceMap

final class PatientMigrationTests: XCTestCase {
    /// Builds an in-memory SwiftData container with both models registered.
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PatientCase.self, Patient.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func makeCase(label: String, secondsAgo: TimeInterval = 0) -> PatientCase {
        let face = CapturedFace(
            vertices: [SIMD3<Float>(0, 0, 0)],
            triangleIndices: [],
            transform: matrix_identity_float4x4,
            blendShapes: [:],
            timestamp: Date().addingTimeInterval(-secondsAgo)
        )
        return PatientCase(
            label: label,
            createdAt: Date().addingTimeInterval(-secondsAgo),
            capturedFace: face,
            metricResults: []
        )
    }

    func test_photos_roundTripThroughPersistence() throws {
        let ctx = try makeContext()
        let face = CapturedFace(
            vertices: [SIMD3<Float>(0, 0, 0)],
            triangleIndices: [],
            transform: matrix_identity_float4x4,
            blendShapes: [:],
            timestamp: Date()
        )
        let frontalJPEG = Data([0xFF, 0xD8, 0x01])
        let obliqueLJPEG = Data([0xFF, 0xD8, 0x02])
        let pc = PatientCase(
            label: "photos",
            capturedFace: face,
            metricResults: [],
            photos: [.frontal: frontalJPEG, .obliqueL: obliqueLJPEG]
        )
        ctx.insert(pc)
        try ctx.save()

        let fetched = try XCTUnwrap(
            try ctx.fetch(FetchDescriptor<PatientCase>(
                predicate: #Predicate { $0.label == "photos" }
            )).first
        )
        XCTAssertEqual(fetched.photo(for: .frontal), frontalJPEG)
        XCTAssertEqual(fetched.photo(for: .obliqueL), obliqueLJPEG)
        XCTAssertNil(fetched.photo(for: .obliqueR))
        XCTAssertEqual(fetched.multiPoseCapture?.photos.count, 2)
        XCTAssertEqual(fetched.multiPoseCapture?.photo(for: .frontal), frontalJPEG)
    }

    func test_bootstrap_rebindsOrphansToUnassignedPatient() throws {
        let ctx = try makeContext()

        // Pre-v0.2 state: cases without a patient.
        let a = makeCase(label: "v0.1 case A", secondsAgo: 100)
        let b = makeCase(label: "v0.1 case B", secondsAgo: 50)
        ctx.insert(a)
        ctx.insert(b)
        try ctx.save()

        // Construct CaseStore — this triggers bootstrap.
        _ = CaseStore(context: ctx)

        // All cases now have a patient, all rebound to "Unassigned".
        let allCases = try ctx.fetch(FetchDescriptor<PatientCase>())
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.allSatisfy { $0.patient != nil })
        let codes = Set(allCases.compactMap { $0.patient?.code })
        XCTAssertEqual(codes, [Patient.unassignedCode])
    }

    func test_bootstrap_isIdempotent() throws {
        let ctx = try makeContext()
        let a = makeCase(label: "X", secondsAgo: 10)
        ctx.insert(a)
        try ctx.save()

        _ = CaseStore(context: ctx)
        _ = CaseStore(context: ctx)
        _ = CaseStore(context: ctx)

        let patients = try ctx.fetch(FetchDescriptor<Patient>())
        XCTAssertEqual(patients.count, 1, "Should not create multiple Unassigned buckets")
    }

    func test_save_assignsUnassignedWhenPatientNil() throws {
        let ctx = try makeContext()
        let store = CaseStore(context: ctx)

        let c = makeCase(label: "newcomer")
        XCTAssertNil(c.patient)

        store.save(c)

        XCTAssertNotNil(c.patient)
        XCTAssertEqual(c.patient?.code, Patient.unassignedCode)
    }

    func test_createPatient_andBindCase() throws {
        let ctx = try makeContext()
        let store = CaseStore(context: ctx)

        let p = store.createPatient(code: "P-007")
        let c = makeCase(label: "Visit 1")
        c.patient = p
        store.save(c)

        let fetched = try ctx.fetch(FetchDescriptor<Patient>(
            predicate: #Predicate { $0.code == "P-007" }
        ))
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.cases.count, 1)
    }

    func test_deletePatient_cascadesCases() throws {
        let ctx = try makeContext()
        let store = CaseStore(context: ctx)

        let p = store.createPatient(code: "P-099")
        let c1 = makeCase(label: "v1"); c1.patient = p
        let c2 = makeCase(label: "v2"); c2.patient = p
        store.save(c1); store.save(c2)

        store.deletePatient(p)

        let remaining = try ctx.fetch(FetchDescriptor<PatientCase>(
            predicate: #Predicate { $0.label == "v1" || $0.label == "v2" }
        ))
        XCTAssertEqual(remaining.count, 0, "Cases should cascade-delete with patient")
    }
}

// MARK: - CapturedFace Codable hardening

/// The decoder is the integrity gate for persisted meshes: structurally-valid JSON with
/// corrupt geometry (truncated buffers, short transforms, out-of-range triangle indices)
/// must throw a `DecodingError` — never reach the unchecked accessors and trap at runtime.
final class CapturedFaceCodableTests: XCTestCase {
    /// A small but fully valid face: 3 vertices, 1 triangle.
    private func makeValidFace() -> CapturedFace {
        CapturedFace(
            vertices: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(0.01, 0, 0), SIMD3<Float>(0, 0.01, 0)],
            triangleIndices: [0, 1, 2],
            transform: matrix_identity_float4x4,
            blendShapes: ["jawOpen": 0.12],
            timestamp: Date(timeIntervalSinceReferenceDate: 700_000_000)
        )
    }

    /// Encode the valid face, then apply a JSON-level mutation to one field.
    private func corruptedPayload(mutating key: String, to value: Any) throws -> Data {
        let data = try JSONEncoder().encode(makeValidFace())
        var obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        obj[key] = value
        return try JSONSerialization.data(withJSONObject: obj)
    }

    private func assertThrowsDecodingError(_ payload: Data,
                                           _ message: String,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        XCTAssertThrowsError(
            try JSONDecoder().decode(CapturedFace.self, from: payload),
            message, file: file, line: line
        ) { error in
            XCTAssertTrue(error is DecodingError,
                          "Expected DecodingError, got \(type(of: error)): \(error)",
                          file: file, line: line)
        }
    }

    func test_roundTrip_preservesEverything() throws {
        let original = makeValidFace()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CapturedFace.self, from: data)

        XCTAssertEqual(decoded, original, "valid pre-existing blobs must decode identically")
        XCTAssertEqual(decoded.vertexCount, 3)
        XCTAssertEqual(decoded.vertices, original.vertices)
        XCTAssertEqual(decoded.triangleIndices, [0, 1, 2])
        XCTAssertEqual(decoded.transform, matrix_identity_float4x4)
        XCTAssertEqual(decoded.blendShapes["jawOpen"], 0.12)
    }

    func test_decode_truncatedVertexData_throws() throws {
        // 8 floats — not a multiple of 3. The old synthesized decoder accepted this and
        // the `vertices` stride accessor then read past the end.
        let payload = try corruptedPayload(
            mutating: "vertexData",
            to: [0.0, 0.0, 0.0, 0.01, 0.0, 0.0, 0.0, 0.01]
        )
        assertThrowsDecodingError(payload, "truncated vertexData must throw")
    }

    func test_decode_fifteenFloatTransform_throws() throws {
        let payload = try corruptedPayload(
            mutating: "transformData",
            to: Array(repeating: 0.0, count: 15)
        )
        assertThrowsDecodingError(payload, "15-float transform must throw")
    }

    func test_decode_negativeTriangleIndex_throws() throws {
        // Any negative Int16 would trap in `UInt32($0)` at mesh-build time.
        let payload = try corruptedPayload(mutating: "triangleIndices", to: [0, 1, -2])
        assertThrowsDecodingError(payload, "negative triangle index must throw")
    }

    func test_decode_outOfRangeTriangleIndex_throws() throws {
        // Index 3 with only 3 vertices (valid range 0..<3).
        let payload = try corruptedPayload(mutating: "triangleIndices", to: [0, 1, 3])
        assertThrowsDecodingError(payload, "triangle index >= vertexCount must throw")
    }

    func test_decode_triangleCountNotMultipleOf3_throws() throws {
        let payload = try corruptedPayload(mutating: "triangleIndices", to: [0, 1])
        assertThrowsDecodingError(payload, "dangling triangle indices must throw")
    }

    func test_decode_emptyMesh_isStillValid() throws {
        // Zero vertices + zero triangles is structurally consistent (used by tests and
        // legacy fixtures) and must keep decoding.
        let empty = CapturedFace(
            vertices: [], triangleIndices: [],
            transform: matrix_identity_float4x4, blendShapes: [:], timestamp: Date()
        )
        let decoded = try JSONDecoder().decode(CapturedFace.self,
                                               from: JSONEncoder().encode(empty))
        XCTAssertEqual(decoded.vertexCount, 0)
    }
}

// MARK: - PatientCase corrupt-payload behavior

/// Corrupt or missing blobs must degrade to the existing nil / empty "Mesh unreadable"
/// paths (and flag `isCorrupt`) instead of trapping.
final class PatientCaseCorruptionTests: XCTestCase {
    private func makeFace() -> CapturedFace {
        CapturedFace(
            vertices: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 1, 0)],
            triangleIndices: [0, 1, 2],
            transform: matrix_identity_float4x4,
            blendShapes: [:],
            timestamp: Date()
        )
    }

    func test_emptyData_yieldsNilFaceAndEmptyMetrics() {
        let pc = PatientCase(label: "x", capturedFace: makeFace(), metricResults: [])
        pc.capturedFaceJSON = Data()
        pc.metricResultsJSON = Data()

        XCTAssertNil(pc.capturedFace)
        XCTAssertEqual(pc.metricResults, [])
        XCTAssertNil(pc.multiPoseCapture)
        XCTAssertTrue(pc.isCorrupt)
    }

    func test_garbageJSON_yieldsNilFace() {
        let pc = PatientCase(label: "x", capturedFace: makeFace(), metricResults: [])
        pc.capturedFaceJSON = Data(#"{"not":"a face"}"#.utf8)

        XCTAssertNil(pc.capturedFace)
        XCTAssertTrue(pc.isCorrupt)
    }

    func test_corruptGeometry_yieldsNilFace_viaDecoderValidation() throws {
        // Structurally-valid JSON whose vertex buffer is truncated: the custom decoder
        // rejects it, so the accessor returns nil instead of trapping downstream.
        let pc = PatientCase(label: "x", capturedFace: makeFace(), metricResults: [])
        var obj = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: pc.capturedFaceJSON) as? [String: Any]
        )
        obj["vertexData"] = [0.0, 0.0]
        pc.capturedFaceJSON = try JSONSerialization.data(withJSONObject: obj)

        XCTAssertNil(pc.capturedFace)
        XCTAssertTrue(pc.isCorrupt)
    }

    func test_garbageAnnotations_yieldEmptyArray() {
        let pc = PatientCase(label: "x", capturedFace: makeFace(), metricResults: [])
        pc.annotationsJSON = Data([0xFF, 0x00, 0x12])

        XCTAssertEqual(pc.annotations, [])
        XCTAssertTrue(pc.isCorrupt)
    }

    func test_healthyRecord_isNotCorrupt() {
        let pc = PatientCase(
            label: "x", capturedFace: makeFace(), metricResults: [],
            obliqueL: makeFace(), obliqueR: makeFace()
        )
        XCTAssertFalse(pc.isCorrupt)
    }

    func test_multiPoseCapture_reassemblesAllThreePoses() {
        let pc = PatientCase(
            label: "x", capturedFace: makeFace(), metricResults: [],
            obliqueL: makeFace(), obliqueR: makeFace(),
            photos: [.frontal: Data([0xFF, 0xD8])]
        )
        let mpc = pc.multiPoseCapture
        XCTAssertNotNil(mpc)
        XCTAssertEqual(mpc?.availablePoses, [.frontal, .obliqueL, .obliqueR])
        XCTAssertEqual(mpc?.photo(for: .frontal), Data([0xFF, 0xD8]))
    }

    func test_multiPoseCapture_survivesCorruptOblique_butNotCorruptFrontal() {
        let pc = PatientCase(
            label: "x", capturedFace: makeFace(), metricResults: [],
            obliqueL: makeFace(), obliqueR: makeFace()
        )

        // Corrupt one oblique: reassembly still works, that pose degrades to nil.
        pc.obliqueLCapturedFaceJSON = Data([0x01])
        let partial = pc.multiPoseCapture
        XCTAssertNotNil(partial)
        XCTAssertNil(partial?.obliqueL)
        XCTAssertNotNil(partial?.obliqueR)
        XCTAssertEqual(partial?.availablePoses, [.frontal, .obliqueR])
        XCTAssertTrue(pc.isCorrupt)

        // Corrupt the frontal: reassembly fails entirely (frontal is required).
        pc.capturedFaceJSON = Data([0x02])
        XCTAssertNil(pc.multiPoseCapture)
    }
}
