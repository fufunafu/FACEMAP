import Foundation

// MARK: - Landmark indices for ARKit's face mesh
//
// ARKit's `ARFaceGeometry` exposes ~1,220 vertices arranged in a fixed topology.
// Because the topology is fixed, a given anatomical landmark always corresponds to the
// same vertex index across devices, sessions, and even minor ARKit updates (Apple has
// kept the topology stable since iPhone X).
//
// CALIBRATION REQUIRED BEFORE CLINICAL USE.
// The values below are seeded from publicly-circulated reference indices. They put
// each landmark in the right neighborhood but should be confirmed empirically against
// a real face mesh on a real device. The recommended procedure is:
//
//   1. Capture a face at neutral expression.
//   2. Render the captured mesh with vertex indices labeled (a debug build flag will
//      enable this in `FaceMeshOverlay` once we wire it up — TODO).
//   3. For each landmark, identify the vertex closest to the anatomical point and
//      update the constant below.
//   4. Re-run unit tests and verify metric outputs against caliper measurements.
//
// Until calibration is performed, **metrics will produce values, but those values are
// not clinically meaningful**. The disclaimer-gate copy reflects this.

enum FaceLandmarkIndices {
    /// Calibrated overrides (from `LandmarkCalibrationStore`) merged over the placeholder
    /// defaults. Use this in metric and analysis code — it transparently picks up whatever
    /// the practitioner has calibrated without touching call sites.
    static var vertexIndex: [AnatomicalLandmark: Int] {
        LandmarkCalibrationStore.shared.effective()
    }

    /// Placeholder vertex indices used until the practitioner calibrates against their
    /// own captured mesh. PLACEHOLDER VALUES — see header comment.
    static let defaultVertexIndex: [AnatomicalLandmark: Int] = [
        .trichion:       16,    // top of forehead, midline
        .glabella:       28,    // mid-brow, midline
        .nasion:         168,   // nasal root
        .pronasale:      9,     // tip of nose
        .subnasale:      164,   // base of columella
        .stomion:        13,    // mouth midline (closed lips)
        .pogonion:       175,   // most anterior chin
        .menton:         152,   // chin midline lowest

        .endocanthionR:  133,   // right eye, medial corner
        .exocanthionR:   33,    // right eye, lateral corner
        .endocanthionL:  362,   // left eye, medial corner
        .exocanthionL:   263,   // left eye, lateral corner

        .zygionR:        234,   // right zygomatic
        .zygionL:        454,   // left zygomatic

        .cheilionR:      61,    // right mouth corner
        .cheilionL:      291,   // left mouth corner

        .alarBaseR:      48,    // right alar base
        .alarBaseL:      278,   // left alar base
    ]

    /// Coarse vertex-group mapping used by the heatmap. Each `FacialRegion` lists vertex
    /// indices that belong to that region. PLACEHOLDER — populated as a small ring around
    /// each region's central landmark; refine during calibration.
    /// Empty groups are tolerated by the heatmap renderer.
    static let regionVertices: [FacialRegion: [Int]] = [
        .forehead:    [16, 28, 21, 54, 103, 67, 109],
        .templeL:     [251, 284],
        .templeR:     [21, 54],
        .browL:       [296, 334, 293],
        .browR:       [66, 105, 63],
        .tearTroughL: [413, 463, 359],
        .tearTroughR: [189, 243, 130],
        .midfaceL:    [330, 266, 425],
        .midfaceR:    [101, 36, 205],
        .nasolabialL: [410, 287],
        .nasolabialR: [186, 57],
        .lipUpper:    [0, 11, 12, 13],
        .lipLower:    [14, 15, 17],
        .perioral:    [61, 291, 0, 17],
        .marionetteL: [432, 434],
        .marionetteR: [212, 214],
        .chin:        [175, 152, 199, 200],
        .prejowlL:    [430, 431],
        .prejowlR:    [210, 211],
        .jawlineL:    [288, 397, 365, 379],
        .jawlineR:    [58, 172, 136, 150],
    ]
}
