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
    /// Rigid head pose (face -> world) paired with the AVERAGED mesh, serialized
    /// column-major as 16 floats. Do NOT use this for photo texture projection —
    /// that needs `photoFaceTransform`, captured at the photo frame.
    private let transformData: [Float]
    /// 52 ARKit blendshape coefficients, keyed by raw string of `ARFaceAnchor.BlendShapeLocation`.
    let blendShapes: [String: Float]
    /// Capture timestamp (UTC).
    let timestamp: Date

    // MARK: Optional enrichment fields (v0.8+). All nil on records saved by older
    // builds; all-or-nothing for the photo-texture path (see `FaceTextureProjection`).

    /// ARKit canonical texture coordinates, flat [u,v, u,v, ...], count == 2 × vertexCount.
    /// Stored per capture (~10 KB) so each blob stays self-describing if Apple ever
    /// changes the face-mesh topology.
    private let textureCoordinateData: [Float]?
    /// `frame.camera.intrinsics` at the photo frame, column-major 3×3 = 9 floats.
    private let cameraIntrinsicsData: [Float]?
    /// Raw (landscape) `capturedImage` size: [width, height]. NOT the rotated photo size.
    private let cameraImageResolution: [Float]?
    /// `frame.camera.transform` (camera → world) at the photo frame, column-major 16 floats.
    private let cameraTransformData: [Float]?
    /// `faceAnchor.transform` (face → world) AT THE PHOTO FRAME — distinct from
    /// `transformData`, which belongs to the averaged mesh. Photo texture projection
    /// must use THIS transform so the mesh lines up with the photo pixels.
    private let photoFaceTransformData: [Float]?
    /// Capture-quality assessment computed at snapshot time. Nil on legacy records.
    let quality: CaptureQuality?

    init(vertices: [SIMD3<Float>],
         triangleIndices: [Int16],
         transform: simd_float4x4,
         blendShapes: [String: Float],
         timestamp: Date,
         textureCoordinates: [SIMD2<Float>]? = nil,
         cameraIntrinsics: simd_float3x3? = nil,
         cameraImageResolution: SIMD2<Float>? = nil,
         cameraTransform: simd_float4x4? = nil,
         photoFaceTransform: simd_float4x4? = nil,
         quality: CaptureQuality? = nil) {
        var flat: [Float] = []
        flat.reserveCapacity(vertices.count * 3)
        for v in vertices { flat.append(v.x); flat.append(v.y); flat.append(v.z) }
        self.vertexData = flat
        self.triangleIndices = triangleIndices
        self.transformData = Self.flatten(transform)
        self.blendShapes = blendShapes
        self.timestamp = timestamp

        self.textureCoordinateData = textureCoordinates.map { uvs in
            var flat: [Float] = []
            flat.reserveCapacity(uvs.count * 2)
            for uv in uvs { flat.append(uv.x); flat.append(uv.y) }
            return flat
        }
        self.cameraIntrinsicsData = cameraIntrinsics.map { k in
            [k.columns.0.x, k.columns.0.y, k.columns.0.z,
             k.columns.1.x, k.columns.1.y, k.columns.1.z,
             k.columns.2.x, k.columns.2.y, k.columns.2.z]
        }
        self.cameraImageResolution = cameraImageResolution.map { [$0.x, $0.y] }
        self.cameraTransformData = cameraTransform.map(Self.flatten)
        self.photoFaceTransformData = photoFaceTransform.map(Self.flatten)
        self.quality = quality
    }

    private static func flatten(_ m: simd_float4x4) -> [Float] {
        [m.columns.0.x, m.columns.0.y, m.columns.0.z, m.columns.0.w,
         m.columns.1.x, m.columns.1.y, m.columns.1.z, m.columns.1.w,
         m.columns.2.x, m.columns.2.y, m.columns.2.z, m.columns.2.w,
         m.columns.3.x, m.columns.3.y, m.columns.3.z, m.columns.3.w]
    }

    private static func unflatten(_ d: [Float]) -> simd_float4x4 {
        simd_float4x4(
            SIMD4(d[0],  d[1],  d[2],  d[3]),
            SIMD4(d[4],  d[5],  d[6],  d[7]),
            SIMD4(d[8],  d[9],  d[10], d[11]),
            SIMD4(d[12], d[13], d[14], d[15])
        )
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
        case textureCoordinateData, cameraIntrinsicsData, cameraImageResolution
        case cameraTransformData, photoFaceTransformData, quality
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let vertexData      = try c.decode([Float].self,           forKey: .vertexData)
        let triangleIndices = try c.decode([Int16].self,           forKey: .triangleIndices)
        let transformData   = try c.decode([Float].self,           forKey: .transformData)
        let blendShapes     = try c.decode([String: Float].self,   forKey: .blendShapes)
        let timestamp       = try c.decode(Date.self,              forKey: .timestamp)
        let textureCoordinateData  = try c.decodeIfPresent([Float].self, forKey: .textureCoordinateData)
        let cameraIntrinsicsData   = try c.decodeIfPresent([Float].self, forKey: .cameraIntrinsicsData)
        let cameraImageResolution  = try c.decodeIfPresent([Float].self, forKey: .cameraImageResolution)
        let cameraTransformData    = try c.decodeIfPresent([Float].self, forKey: .cameraTransformData)
        let photoFaceTransformData = try c.decodeIfPresent([Float].self, forKey: .photoFaceTransformData)
        let quality                = try c.decodeIfPresent(CaptureQuality.self, forKey: .quality)

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

        // Optional fields: absent is fine (legacy blob), but a PRESENT field with a
        // wrong count means corruption — our encoder only ever writes well-formed
        // payloads, and the accessors below index without bounds checks.
        if let t = textureCoordinateData, t.count != vertexCount * 2 {
            throw DecodingError.dataCorruptedError(
                forKey: .textureCoordinateData, in: c,
                debugDescription: "textureCoordinateData count \(t.count) != 2 × \(vertexCount)"
            )
        }
        if let k = cameraIntrinsicsData, k.count != 9 {
            throw DecodingError.dataCorruptedError(
                forKey: .cameraIntrinsicsData, in: c,
                debugDescription: "cameraIntrinsicsData count \(k.count) != 9"
            )
        }
        if let r = cameraImageResolution, r.count != 2 || r[0] <= 0 || r[1] <= 0 {
            throw DecodingError.dataCorruptedError(
                forKey: .cameraImageResolution, in: c,
                debugDescription: "cameraImageResolution \(r) is not two positive floats"
            )
        }
        if let m = cameraTransformData, m.count != 16 {
            throw DecodingError.dataCorruptedError(
                forKey: .cameraTransformData, in: c,
                debugDescription: "cameraTransformData count \(m.count) != 16"
            )
        }
        if let m = photoFaceTransformData, m.count != 16 {
            throw DecodingError.dataCorruptedError(
                forKey: .photoFaceTransformData, in: c,
                debugDescription: "photoFaceTransformData count \(m.count) != 16"
            )
        }

        self.vertexData = vertexData
        self.triangleIndices = triangleIndices
        self.transformData = transformData
        self.blendShapes = blendShapes
        self.timestamp = timestamp
        self.textureCoordinateData = textureCoordinateData
        self.cameraIntrinsicsData = cameraIntrinsicsData
        self.cameraImageResolution = cameraImageResolution
        self.cameraTransformData = cameraTransformData
        self.photoFaceTransformData = photoFaceTransformData
        self.quality = quality
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

    var transform: simd_float4x4 { Self.unflatten(transformData) }

    /// Number of vertices. ARKit's current face mesh exposes 1,220 vertices.
    var vertexCount: Int { vertexData.count / 3 }

    // MARK: Optional enrichment accessors

    /// ARKit canonical texture coordinates, one per vertex. Nil on legacy records.
    var textureCoordinates: [SIMD2<Float>]? {
        guard let d = textureCoordinateData else { return nil }
        var out: [SIMD2<Float>] = []
        out.reserveCapacity(d.count / 2)
        var i = 0
        while i < d.count {
            out.append(SIMD2(d[i], d[i+1]))
            i += 2
        }
        return out
    }

    /// Raw-buffer camera intrinsics at the photo frame. Nil on legacy records.
    var cameraIntrinsics: simd_float3x3? {
        guard let k = cameraIntrinsicsData else { return nil }
        return simd_float3x3(
            SIMD3(k[0], k[1], k[2]),
            SIMD3(k[3], k[4], k[5]),
            SIMD3(k[6], k[7], k[8])
        )
    }

    /// Raw landscape `capturedImage` size (W, H). Nil on legacy records.
    var rawImageResolution: SIMD2<Float>? {
        guard let r = cameraImageResolution else { return nil }
        return SIMD2(r[0], r[1])
    }

    /// Camera → world at the photo frame. Nil on legacy records.
    var cameraTransform: simd_float4x4? {
        cameraTransformData.map(Self.unflatten)
    }

    /// Face → world at the photo frame — the transform photo texture projection must
    /// use (`transform` belongs to the averaged mesh, not the photo). Nil on legacy records.
    var photoFaceTransform: simd_float4x4? {
        photoFaceTransformData.map(Self.unflatten)
    }

    /// True when every field the photo-texture path needs is present
    /// (all-or-nothing contract; see `FaceTextureProjection`).
    var hasPhotoProjectionData: Bool {
        textureCoordinateData != nil
            && cameraIntrinsicsData != nil
            && cameraImageResolution != nil
            && cameraTransformData != nil
            && photoFaceTransformData != nil
    }
}
