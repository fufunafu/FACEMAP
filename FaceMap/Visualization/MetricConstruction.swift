import Foundation
import simd
import UIKit

/// A geometric explanation of how a metric arrived at its value.
/// Rendered as RealityKit entities on the analysis-screen 3D mesh so the
/// practitioner can see the lines, centroids, and labels that produced
/// each measurement.
///
/// All positions are in ARKit **face-local** coordinates (pre-centroid).
/// The renderer applies the same centroid shift the mesh uses, so the
/// markers, lines, and labels align exactly with the rendered face surface.
struct MetricConstruction {
    /// Stable id of the metric this construction explains.
    let metricId: String
    let markers: [ConstructionMarker]
    let segments: [ConstructionSegment]
    let labels: [ConstructionLabel]

    init(metricId: String,
         markers: [ConstructionMarker] = [],
         segments: [ConstructionSegment] = [],
         labels: [ConstructionLabel] = []) {
        self.metricId = metricId
        self.markers = markers
        self.segments = segments
        self.labels = labels
    }

    var isEmpty: Bool {
        markers.isEmpty && segments.isEmpty && labels.isEmpty
    }
}

/// Small filled sphere at a single anatomical point (a landmark, a region centroid,
/// or a mirrored point used in the metric's math).
struct ConstructionMarker {
    let position: SIMD3<Float>
    let color: UIColor
    var radius: Float = 0.0025         // metres in face-local

    init(position: SIMD3<Float>, color: UIColor, radius: Float = 0.0025) {
        self.position = position
        self.color = color
        self.radius = radius
    }
}

/// Thin line between two anatomical points. Rendered as a stretched box so it has
/// actual 3D presence at oblique angles.
struct ConstructionSegment {
    let start: SIMD3<Float>
    let end: SIMD3<Float>
    let color: UIColor
    var thickness: Float = 0.0008      // metres in face-local

    init(start: SIMD3<Float>, end: SIMD3<Float>, color: UIColor, thickness: Float = 0.0008) {
        self.start = start
        self.end = end
        self.color = color
        self.thickness = thickness
    }
}

/// Short text floated at a point in space. Billboards toward the camera so it
/// remains readable as the user orbits the mesh.
struct ConstructionLabel {
    let position: SIMD3<Float>
    let text: String
    let color: UIColor
    var fontPointSize: CGFloat = 12

    init(position: SIMD3<Float>, text: String, color: UIColor, fontPointSize: CGFloat = 12) {
        self.position = position
        self.text = text
        self.color = color
        self.fontPointSize = fontPointSize
    }
}
