import XCTest
import simd
@testable import FaceMap

/// Backwards/forwards compatibility of the `CapturedFace` blob format across the
/// v0.8 enrichment fields (texture coordinates, camera data, quality).
final class CapturedFaceCompatTests: XCTestCase {

    private let identity16 = "[1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]"

    /// A blob exactly as a pre-enrichment build would have written it: the five
    /// original keys and nothing else.
    private func legacyJSON() -> Data {
        """
        {
          "vertexData": [0,0,0, 0.01,0,0, 0,0.01,0],
          "triangleIndices": [0,1,2],
          "transformData": \(identity16),
          "blendShapes": {"jawOpen": 0.1},
          "timestamp": 700000000
        }
        """.data(using: .utf8)!
    }

    func test_legacyBlob_decodes_withAllNewFieldsNil() throws {
        let face = try JSONDecoder().decode(CapturedFace.self, from: legacyJSON())
        XCTAssertEqual(face.vertexCount, 3)
        XCTAssertNil(face.textureCoordinates)
        XCTAssertNil(face.cameraIntrinsics)
        XCTAssertNil(face.rawImageResolution)
        XCTAssertNil(face.cameraTransform)
        XCTAssertNil(face.photoFaceTransform)
        XCTAssertNil(face.quality)
        XCTAssertFalse(face.hasPhotoProjectionData)
    }

    func test_allNilFace_encodesWithoutNewKeys() throws {
        let face = CapturedFace(vertices: [SIMD3(0, 0, 0)],
                                triangleIndices: [],
                                transform: matrix_identity_float4x4,
                                blendShapes: [:],
                                timestamp: Date())
        let data = try JSONEncoder().encode(face)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys),
                       ["vertexData", "triangleIndices", "transformData", "blendShapes", "timestamp"],
                       "an all-nil capture must serialize byte-layout-compatible with legacy blobs")
    }

    func test_fullyPopulatedFace_roundTrips() throws {
        var camera = matrix_identity_float4x4
        camera.columns.3 = SIMD4(0, 0.02, 0.1, 1)
        var photoFace = matrix_identity_float4x4
        photoFace.columns.3 = SIMD4(0.001, 0.002, -0.4, 1)
        let intrinsics = simd_float3x3(
            SIMD3(1000, 0, 0), SIMD3(0, 1100, 0), SIMD3(700, 500, 1)
        )
        let quality = CaptureQuality.compute(framesAveraged: 10, meanJitterMM: 0.05,
                                             maxJitterMM: 0.2, yawErrorDegrees: 1,
                                             pitchDegrees: 2, rollDegrees: -1,
                                             expressionMax: 0.3, gateViolations: [])
        let original = CapturedFace(vertices: [SIMD3(0, 0, 0), SIMD3(0.01, 0, 0), SIMD3(0, 0.01, 0)],
                                    triangleIndices: [0, 1, 2],
                                    transform: matrix_identity_float4x4,
                                    blendShapes: ["jawOpen": 0.05],
                                    timestamp: Date(timeIntervalSinceReferenceDate: 700000000),
                                    textureCoordinates: [SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1)],
                                    cameraIntrinsics: intrinsics,
                                    cameraImageResolution: SIMD2(1440, 1080),
                                    cameraTransform: camera,
                                    photoFaceTransform: photoFace,
                                    quality: quality)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CapturedFace.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.hasPhotoProjectionData)
        XCTAssertEqual(decoded.textureCoordinates?.count, 3)
        XCTAssertEqual(decoded.cameraIntrinsics?[2][0], 700)
        XCTAssertEqual(decoded.rawImageResolution, SIMD2(1440, 1080))
        XCTAssertEqual(decoded.photoFaceTransform?.columns.3.z ?? 0, -0.4, accuracy: 1e-6)
        XCTAssertEqual(decoded.quality?.framesAveraged, 10)
    }

    // MARK: Malformed present-fields must throw (a present field with a wrong count
    // is corruption, not a legacy blob).

    private func decodeExpectingCorruption(_ extraKeyValues: String,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        let json = """
        {
          "vertexData": [0,0,0, 0.01,0,0, 0,0.01,0],
          "triangleIndices": [0,1,2],
          "transformData": \(identity16),
          "blendShapes": {},
          "timestamp": 700000000,
          \(extraKeyValues)
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(CapturedFace.self, from: json),
                             file: file, line: line) { error in
            guard case DecodingError.dataCorrupted = error else {
                XCTFail("expected dataCorrupted, got \(error)", file: file, line: line)
                return
            }
        }
    }

    func test_wrongTexcoordCount_throws() {
        // 3 vertices need 6 floats; 5 is corrupt.
        decodeExpectingCorruption("\"textureCoordinateData\": [0,0, 1,0, 0]")
    }

    func test_wrongIntrinsicsCount_throws() {
        decodeExpectingCorruption("\"cameraIntrinsicsData\": [1000,0,0, 0,1100,0, 700,500]")
    }

    func test_wrongResolutionCount_throws() {
        decodeExpectingCorruption("\"cameraImageResolution\": [1440]")
    }

    func test_nonPositiveResolution_throws() {
        decodeExpectingCorruption("\"cameraImageResolution\": [1440, 0]")
    }

    func test_wrongCameraTransformCount_throws() {
        decodeExpectingCorruption("\"cameraTransformData\": [1,0,0,0]")
    }

    func test_wrongPhotoFaceTransformCount_throws() {
        decodeExpectingCorruption("\"photoFaceTransformData\": [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0]")
    }
}
