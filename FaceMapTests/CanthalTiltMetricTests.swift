import XCTest
import simd
@testable import FaceMap

final class CanthalTiltMetricTests: XCTestCase {
    func test_targetTilt_isWithinTarget() {
        // ~5° upward tilt on both sides.
        // tan(5°) ≈ 0.0875. Set Δy = 0.00875 over Δx = 0.10.
        let endoR = SIMD3<Float>(-0.05, 0, 0)
        let exoR  = SIMD3<Float>(-0.15, 0.00875, 0)   // outward + up
        let endoL = SIMD3<Float>( 0.05, 0, 0)
        let exoL  = SIMD3<Float>( 0.15, 0.00875, 0)
        let face = SyntheticFace.make([
            .endocanthionR: endoR, .exocanthionR: exoR,
            .endocanthionL: endoL, .exocanthionL: exoL,
        ])
        let r = CanthalTiltMetric().evaluate(face)
        XCTAssertTrue(r.isWithinTarget, "expected tilt in 4–7°, got value=\(r.value), notes=\(r.notes ?? "")")
        XCTAssertEqual(r.regions, [])
    }

    func test_negativeTilt_flagsTearTrough() {
        // Negative tilt on right side (exo lower than endo).
        let endoR = SIMD3<Float>(-0.05, 0, 0)
        let exoR  = SIMD3<Float>(-0.15, -0.02, 0)
        let endoL = SIMD3<Float>( 0.05, 0, 0)
        let exoL  = SIMD3<Float>( 0.15, 0.00875, 0)
        let face = SyntheticFace.make([
            .endocanthionR: endoR, .exocanthionR: exoR,
            .endocanthionL: endoL, .exocanthionL: exoL,
        ])
        let r = CanthalTiltMetric().evaluate(face)
        XCTAssertFalse(r.isWithinTarget)
        XCTAssertTrue(r.regions.contains(.tearTroughR), "got regions=\(r.regions)")
    }
}
