import Foundation
import simd

/// Neutral "clay" tint shared by the mesh material and the texture bakers —
/// a slightly warm grey matching Theme.canvas-on-mesh.
enum MeshPalette {
    static let neutral = SIMD4<Float>(0.78, 0.78, 0.80, 1)
}

/// Domain-aware mesh tints, shared by the heatmap texture baker and any severity
/// swatches. (Moved from a private extension in `FaceMeshOverlay` when heatmap
/// rendering became texture-based.)
extension FaceDomain {
    /// SIMD4 RGBA tint for the mesh, blending the domain hue with a skin-neutral
    /// baseline by severity. `.normal` returns the neutral.
    func meshTint(_ severity: MetricResult.Severity) -> SIMD4<Float> {
        let neutral = MeshPalette.neutral
        let target  = self.hueRGB
        let mix = severityMix(severity)
        return neutral * (1 - mix) + target * mix
    }

    /// 0–1 blend factor for a severity level — doubles as the heatmap overlay's
    /// alpha so `.normal` regions stay fully transparent.
    func severityMix(_ severity: MetricResult.Severity) -> Float {
        switch severity {
        case .normal:      return 0.0
        case .mild:        return 0.35
        case .moderate:    return 0.70
        case .significant: return 1.0
        }
    }

    /// SIMD4 representation of the domain hue used for mesh shading.
    var hueRGB: SIMD4<Float> {
        switch self {
        case .skinQuality: return SIMD4(0.478, 0.502, 0.580, 1) // #7A8094 slate
        case .facialShape: return SIMD4(0.651, 0.706, 0.867, 1) // #A6B4DD periwinkle
        case .proportions: return SIMD4(0.604, 0.698, 0.839, 1) // #9AB2D6 soft blue
        case .symmetry:    return SIMD4(0.914, 0.710, 0.878, 1) // #E9B5E0 magenta-pink
        case .expression:  return SIMD4(0.788, 0.733, 0.933, 1) // #C9BBEE lavender
        }
    }
}
