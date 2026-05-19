import Foundation
import RealityKit
import simd

/// iOS-17-compatible billboarding. Apple's native `BillboardComponent` is iOS 18+,
/// so we tag label entities with this marker component and a `System` rotates them
/// each frame to face the camera.
///
/// In FaceMap's `nonAR` `ARView`, the camera is fixed in world space and only the
/// mesh entity (and its children — the labels) rotates via `FaceMeshController`.
/// Counter-rotating each label by its parent's inverse world orientation keeps the
/// label's world orientation at identity (= facing the camera).
struct LabelBillboardComponent: Component {
    init() {}
}

final class BillboardSystem: System {
    static let query = EntityQuery(where: .has(LabelBillboardComponent.self))

    init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach { entity in
            guard let parent = entity.parent else { return }
            let parentWorld = parent.orientation(relativeTo: nil)
            entity.orientation = parentWorld.inverse
        }
    }

    /// Call once at app launch to make the system active.
    static func register() {
        LabelBillboardComponent.registerComponent()
        BillboardSystem.registerSystem()
    }
}
