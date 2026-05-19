import Foundation
import RealityKit
import UIKit
import simd

/// Turns a `[MetricConstruction]` into RealityKit child entities attached to a
/// parent `ModelEntity` (typically the face-mesh entity). The renderer applies
/// the mesh's centroid offset so the construction aligns with the rendered face.
enum MetricConstructionRenderer {

    /// Attach all markers, segments, and labels for the given constructions to
    /// the parent mesh entity. The parent's vertices are expected to have been
    /// pre-centered by `centroid`, so we apply the same shift to every primitive.
    static func render(_ constructions: [MetricConstruction],
                       on parent: ModelEntity,
                       centroid: SIMD3<Float>,
                       inverseScaleForLabels: Float = 3.0) {
        for c in constructions {
            for m in c.markers   { parent.addChild(buildMarker(m, centroid: centroid)) }
            for s in c.segments  { parent.addChild(buildSegment(s, centroid: centroid)) }
            for l in c.labels    {
                parent.addChild(
                    buildLabel(l, centroid: centroid, inverseScale: inverseScaleForLabels)
                )
            }
        }
    }

    // MARK: - Marker (sphere)

    private static func buildMarker(_ m: ConstructionMarker, centroid: SIMD3<Float>) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: m.radius)
        var mat = UnlitMaterial(color: m.color)
        mat.blending = .opaque
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.position = m.position - centroid
        return entity
    }

    // MARK: - Segment (thin box stretched along Y; iOS 17 has no generateCylinder)

    private static func buildSegment(_ s: ConstructionSegment, centroid: SIMD3<Float>) -> ModelEntity {
        let start = s.start - centroid
        let end   = s.end   - centroid
        let delta = end - start
        let length = simd_length(delta)
        guard length > 1e-6 else {
            return buildMarker(
                ConstructionMarker(position: s.start, color: s.color, radius: s.thickness),
                centroid: centroid
            )
        }

        // `generateCylinder` is iOS 18+. A thin box at sub-millimetre thickness reads
        // identically as a line at any practical zoom.
        let mesh = MeshResource.generateBox(
            width: s.thickness * 2,
            height: length,
            depth: s.thickness * 2
        )
        var mat = UnlitMaterial(color: s.color)
        mat.blending = .opaque
        let entity = ModelEntity(mesh: mesh, materials: [mat])

        // Default box mesh is aligned along +Y; rotate from +Y to the segment direction.
        let direction = delta / length
        let yAxis = SIMD3<Float>(0, 1, 0)
        entity.orientation = simd_quaternion(yAxis, direction)
        entity.position = (start + end) / 2
        return entity
    }

    // MARK: - Label (3D text + custom billboarding)

    private static func buildLabel(_ l: ConstructionLabel,
                                   centroid: SIMD3<Float>,
                                   inverseScale: Float) -> ModelEntity {
        let textMesh = MeshResource.generateText(
            l.text,
            extrusionDepth: 0.0,
            font: .systemFont(ofSize: l.fontPointSize, weight: .semibold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        var mat = UnlitMaterial(color: l.color)
        mat.blending = .opaque
        let entity = ModelEntity(mesh: textMesh, materials: [mat])

        let pointToWorld: Float = 0.0012
        let s = pointToWorld / inverseScale
        entity.scale = SIMD3<Float>(s, s, s)
        entity.position = l.position - centroid

        // Centre horizontally — generateText anchors at the bottom-left.
        let bounds = entity.visualBounds(relativeTo: entity)
        let halfWidth = bounds.extents.x / 2
        entity.position.x -= halfWidth * s

        // iOS-17-compatible billboarding (see BillboardSystem.swift).
        entity.components.set(LabelBillboardComponent())
        return entity
    }
}

/// Build a quaternion that rotates `from` to `to` (both unit vectors).
/// Handles the antiparallel edge case (rotation by 180°).
private func simd_quaternion(_ from: SIMD3<Float>, _ to: SIMD3<Float>) -> simd_quatf {
    let dot = simd_dot(from, to)
    if dot > 0.9999 { return simd_quatf(angle: 0, axis: from) }
    if dot < -0.9999 {
        let axis = abs(from.x) < 0.9
            ? simd_normalize(simd_cross(from, SIMD3<Float>(1, 0, 0)))
            : simd_normalize(simd_cross(from, SIMD3<Float>(0, 1, 0)))
        return simd_quatf(angle: .pi, axis: axis)
    }
    let axis = simd_normalize(simd_cross(from, to))
    let angle = acos(max(-1, min(1, dot)))
    return simd_quatf(angle: angle, axis: axis)
}
