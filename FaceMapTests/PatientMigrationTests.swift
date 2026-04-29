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
