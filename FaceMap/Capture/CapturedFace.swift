import Foundation
import simd

/// Snapshot of an `ARFaceAnchor` taken at a moment in time.
/// Stable across app sessions: vertex N is always the same anatomical point because
/// ARKit's face mesh has fixed topology.
struct CapturedFace: Codable, Hashable {
    /// Vertex positions in face-local coordinates (meters), serialized as flat [x,y,z, x,y,z, ...].
    private let vertexData: [Float]
    /// Triangle list. Each consecutive triple of indices defines one triangle.
    let triangleIndices: [Int16]
    /// Rigid head pose (face -> world), serialized column-major as 16 floats.
    private let transformData: [Float]
    /// 52 ARKit blendshape coefficients, keyed by raw string of `ARFaceAnchor.BlendShapeLocation`.
    let blendShapes: [String: Float]
    /// Capture timestamp (UTC).
    let timestamp: Date

    init(vertices: [SIMD3<Float>],
         triangleIndices: [Int16],
         transform: simd_float4x4,
         blendShapes: [String: Float],
         timestamp: Date) {
        var flat: [Float] = []
        flat.reserveCapacity(vertices.count * 3)
        for v in vertices { flat.append(v.x); flat.append(v.y); flat.append(v.z) }
        self.vertexData = flat
        self.triangleIndices = triangleIndices
        self.transformData = [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w,
        ]
        self.blendShapes = blendShapes
        self.timestamp = timestamp
    }

    // MARK: - Codable

    // Encoding stays synthesized-equivalent (same keys, same layout) so blobs written by
    // older builds remain byte-compatible. Decoding is custom: the accessors below stride
    // and index the raw arrays without bounds checks, so a structurally-valid-but-corrupt
    // payload (truncated vertex buffer, short transform, out-of-range triangle index) must
    // be rejected *here*, where failure flows into the existing nil → "Mesh unreadable"
    // paths (`PatientCase.capturedFace` returns nil on decode failure).
    private enum CodingKeys: String, CodingKey {
        case vertexData, triangleIndices, transformData, blendShapes, timestamp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let vertexData      = try c.decode([Float].self,           forKey: .vertexData)
        let triangleIndices = try c.decode([Int16].self,           forKey: .triangleIndices)
        let transformData   = try c.decode([Float].self,           forKey: .transformData)
        let blendShapes     = try c.decode([String: Float].self,   forKey: .blendShapes)
        let timestamp       = try c.decode(Date.self,              forKey: .timestamp)

        guard vertexData.count % 3 == 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .vertexData, in: c,
                debugDescription: "vertexData count \(vertexData.count) is not a multiple of 3"
            )
        }
        guard transformData.count == 16 else {
            throw DecodingError.dataCorruptedError(
                forKey: .transformData, in: c,
                debugDescription: "transformData count \(transformData.count) != 16"
            )
        }
        guard triangleIndices.count % 3 == 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .triangleIndices, in: c,
                debugDescription: "triangleIndices count \(triangleIndices.count) is not a multiple of 3"
            )
        }
        let vertexCount = vertexData.count / 3
        guard triangleIndices.allSatisfy({ Int($0) >= 0 && Int($0) < vertexCount }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .triangleIndices, in: c,
                debugDescription: "triangleIndices contains an index outside 0..<\(vertexCount)"
            )
        }

        self.vertexData = vertexData
        self.triangleIndices = triangleIndices
        self.transformData = transformData
        self.blendShapes = blendShapes
        self.timestamp = timestamp
    }

    var vertices: [SIMD3<Float>] {
        var out: [SIMD3<Float>] = []
        out.reserveCapacity(vertexData.count / 3)
        var i = 0
        while i < vertexData.count {
            out.append(SIMD3(vertexData[i], vertexData[i+1], vertexData[i+2]))
            i += 3
        }
        return out
    }

    var transform: simd_float4x4 {
        let d = transformData
        return simd_float4x4(
            SIMD4(d[0],  d[1],  d[2],  d[3]),
            SIMD4(d[4],  d[5],  d[6],  d[7]),
            SIMD4(d[8],  d[9],  d[10], d[11]),
            SIMD4(d[12], d[13], d[14], d[15])
        )
    }

    /// Number of vertices. ARKit's current face mesh exposes 1,220 vertices.
    var vertexCount: Int { vertexData.count / 3 }
}
