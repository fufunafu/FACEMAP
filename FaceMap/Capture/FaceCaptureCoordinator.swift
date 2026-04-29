import Foundation
import ARKit

/// Helpers around ARKit face tracking that live outside the SwiftUI host.
/// (The session-delegate logic itself is on `FaceCaptureView.Coordinator` so it can hold a reference to the ARView.)
enum FaceTracking {
    static var isSupportedOnThisDevice: Bool {
        ARFaceTrackingConfiguration.isSupported
    }
}
