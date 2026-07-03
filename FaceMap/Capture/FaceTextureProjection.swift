import Foundation
import simd

/// Projects face-local mesh vertices into the stored clinical photo.
///
/// This is THE single source of truth for photo↔mesh registration — renderers must
/// call `photoUV` rather than re-deriving camera matrices, because the orientation
/// remap below must exactly match how the photo was written at capture time.
///
/// The stored photo is the raw `ARFrame.capturedImage` rotated with
/// `CIImage.oriented(.right)` (landscape sensor → portrait) and deliberately
/// UNMIRRORED (clinical convention: the patient as others see them). No mirror flip
/// is applied here — the patient's left cheek appears on the viewer's right, exactly
/// as the mesh projects.
///
/// Projection formula (doc-comment contract, verified by `FaceTextureProjectionTests`):
///
///     Let fx = K[0][0], fy = K[1][1], cx = K[2][0], cy = K[2][1]   (simd column-major)
///     W = rawImageResolution.x, H = rawImageResolution.y            (landscape: W > H)
///
///     1. World:   p_w = photoFaceTransform · [v.x, v.y, v.z, 1]
///     2. Camera:  p_c = cameraTransform⁻¹ · p_w
///                 (ARKit camera space: +X right, +Y up, +Z backward; visible ⇒ p_c.z < 0)
///     3. Raw pixels (landscape sensor image, origin top-left, y down — the space K is
///        defined in):
///                 u_raw = fx · ( p_c.x / −p_c.z) + cx
///                 v_raw = cy − fy · ( p_c.y / −p_c.z)               (image y down, camera y up)
///     4. Stored photo = raw buffer rotated 90° clockwise by `.oriented(.right)`:
///                 photo width = H, photo height = W
///                 x_photo = H − v_raw
///                 y_photo = u_raw
///        (Corner check: raw top-left (0,0) → photo top-right (H,0); raw bottom-left →
///        photo top-left.)
///     5. Normalized, origin top-left of the stored photo (Metal-style):
///                 uv = ( x_photo / H , y_photo / W )
///
/// If a renderer ever wants ARKit's matrix form instead, `camera.projectionMatrix(
/// for: .portrait, viewportSize: CGSize(width: H, height: W), ...)` is equivalent —
/// but the primitives stored on `CapturedFace` (intrinsics + resolution + camera
/// transform) are orientation-free facts of the frame and do not freeze a viewport
/// choice into every blob.
enum FaceTextureProjection {

    /// Projects a face-local vertex into the normalized, top-left-origin UV of the
    /// stored (portrait, unmirrored) photo. Returns nil when the point is behind the
    /// camera. The returned UV may lie outside 0...1 when the vertex projects outside
    /// the photo frame — callers decide how to handle that (typically fade to neutral).
    ///
    /// - Parameters:
    ///   - vertex: face-local vertex position (meters).
    ///   - photoFaceTransform: face → world at the PHOTO frame
    ///     (`CapturedFace.photoFaceTransform`, NOT the legacy averaged-mesh `transform`).
    ///   - cameraTransform: camera → world at the photo frame.
    ///   - intrinsics: raw-buffer camera intrinsics (3×3, column-major).
    ///   - rawImageResolution: raw landscape `capturedImage` size (W, H), W > H.
    static func photoUV(vertex: SIMD3<Float>,
                        photoFaceTransform: simd_float4x4,
                        cameraTransform: simd_float4x4,
                        intrinsics: simd_float3x3,
                        rawImageResolution: SIMD2<Float>) -> SIMD2<Float>? {
        let pWorld = photoFaceTransform * SIMD4(vertex.x, vertex.y, vertex.z, 1)
        let pCam = cameraTransform.inverse * pWorld

        // ARKit camera space looks down −Z; a point at or behind the camera plane
        // cannot be sampled.
        guard pCam.z < 0 else { return nil }

        let fx = intrinsics[0][0]
        let fy = intrinsics[1][1]
        let cx = intrinsics[2][0]
        let cy = intrinsics[2][1]
        let w = rawImageResolution.x
        let h = rawImageResolution.y

        let uRaw = fx * (pCam.x / -pCam.z) + cx
        let vRaw = cy - fy * (pCam.y / -pCam.z)

        // .oriented(.right): landscape buffer rotated 90° clockwise into the portrait photo.
        let xPhoto = h - vRaw
        let yPhoto = uRaw

        return SIMD2(xPhoto / h, yPhoto / w)
    }
}
