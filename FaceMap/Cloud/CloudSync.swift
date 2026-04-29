import Foundation

/// Cloud-sync interface. v0.1 ships `NoopCloudSync` so nothing leaves the device by default.
/// Phase 2 swaps in a real implementation backed by the Vercel Next.js API.
protocol CloudSync {
    func upload(_ patientCase: PatientCase) async throws
    func delete(caseId: UUID) async throws
    func list() async throws -> [PatientCase]
}

struct NoopCloudSync: CloudSync {
    func upload(_ patientCase: PatientCase) async throws {}
    func delete(caseId: UUID) async throws {}
    func list() async throws -> [PatientCase] { [] }
}
