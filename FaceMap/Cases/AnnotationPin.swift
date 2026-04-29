import Foundation
import simd

/// Practitioner-placed marker on the captured 3D mesh. Stored in face-local
/// (mesh-space) coordinates so it follows the mesh through any orbit/zoom and
/// renders correctly in PDF exports of any view angle.
struct AnnotationPin: Codable, Hashable, Identifiable {
    var id: UUID
    /// Mesh-space position (face-local, with origin at the mesh centroid).
    var position: SIMD3<Float>
    /// One-line label. No PII.
    var label: String
    /// Optional severity bucket the practitioner assigns to the pin.
    var severity: MetricResult.Severity?
    /// Optional domain bucket — gives the pin a colour tied to the framework.
    var domain: FaceDomain?
    var createdAt: Date

    init(id: UUID = UUID(),
         position: SIMD3<Float>,
         label: String,
         severity: MetricResult.Severity? = nil,
         domain: FaceDomain? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.position = position
        self.label = label
        self.severity = severity
        self.domain = domain
        self.createdAt = createdAt
    }

    // MARK: - Codable for SIMD3<Float>

    private enum CodingKeys: String, CodingKey {
        case id, x, y, z, label, severity, domain, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        let x = try c.decode(Float.self, forKey: .x)
        let y = try c.decode(Float.self, forKey: .y)
        let z = try c.decode(Float.self, forKey: .z)
        self.position = SIMD3<Float>(x, y, z)
        self.label = try c.decode(String.self, forKey: .label)
        self.severity = try c.decodeIfPresent(MetricResult.Severity.self, forKey: .severity)
        self.domain = try c.decodeIfPresent(FaceDomain.self, forKey: .domain)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(position.x, forKey: .x)
        try c.encode(position.y, forKey: .y)
        try c.encode(position.z, forKey: .z)
        try c.encode(label, forKey: .label)
        try c.encodeIfPresent(severity, forKey: .severity)
        try c.encodeIfPresent(domain, forKey: .domain)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
