import Foundation
import RealityKit
import UIKit

/// Shared 3-point light rig for every face-mesh viewport (analysis viewer,
/// calibration, comparison, PDF snapshots). Replaces the old single directional
/// light, whose one-angle shading left the whole unlit side pure black.
///
/// The rig is added to the WORLD anchor (not the mesh entity), so lighting stays
/// viewer-fixed while the entity rotates — correct for a turntable viewer, and it
/// keeps the deliberate "spotlight on black" look: key defines form, warm fill
/// lifts the shadow side, cool rim separates the silhouette from the black
/// background so it reads as studio rather than void.
enum FaceMeshLighting {

    /// Adds the rig to `anchor` and applies render options to `arView`.
    /// - Parameter castsShadows: enable the key light's shadow map. Off for small
    ///   thumbnails (cost + shadow acne at tiny scale), on for full-screen/snapshots.
    static func apply(to arView: ARView, anchor: AnchorEntity, castsShadows: Bool) {
        arView.renderOptions.formUnion([
            .disableMotionBlur,
            .disableDepthOfField,
            .disableCameraGrain,
            .disableGroundingShadows,
            .disablePersonOcclusion,
        ])

        // Optional IBL, progressive enhancement: bundle a `StudioLighting.skybox/`
        // folder (1k neutral-studio EXR) and it lights up automatically; without it
        // the 3-point rig alone is the shipping look. Affects lighting only — the
        // background stays whatever color the view set.
        if let environment = try? EnvironmentResource.load(named: "StudioLighting") {
            arView.environment.lighting.resource = environment
            arView.environment.lighting.intensityExponent = 0.7
        }

        // Key: defines the form. Near the old light's angle to preserve the
        // established look, slightly brighter now that fill/rim share the load.
        let key = DirectionalLight()
        key.light.color = .white
        key.light.intensity = 1800
        key.orientation = simd_quatf(angle: -.pi / 6, axis: [1, 0, 0]) *
                          simd_quatf(angle:  .pi / 12, axis: [0, 1, 0])
        if castsShadows {
            key.shadow = DirectionalLightComponent.Shadow(maximumDistance: 0.5, depthBias: 2.0)
        }
        anchor.addChild(key)

        // Fill: warm, low intensity, from the opposite side — kills the pure-black
        // shadow half without flattening the form.
        let fill = DirectionalLight()
        fill.light.color = UIColor(red: 1, green: 0.96, blue: 0.92, alpha: 1)
        fill.light.intensity = 500
        fill.orientation = simd_quatf(angle: -.pi / 18, axis: [1, 0, 0]) *
                           simd_quatf(angle: -.pi * 2 / 9, axis: [0, 1, 0])
        anchor.addChild(fill)

        // Rim: cool, from behind-above — silhouette separation against black.
        let rim = DirectionalLight()
        rim.light.color = UIColor(red: 0.92, green: 0.95, blue: 1, alpha: 1)
        rim.light.intensity = 900
        rim.orientation = simd_quatf(angle: .pi * 25 / 36, axis: [1, 0, 0]) *
                          simd_quatf(angle: .pi, axis: [0, 1, 0])
        anchor.addChild(rim)
    }
}
