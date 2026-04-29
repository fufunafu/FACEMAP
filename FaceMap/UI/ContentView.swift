import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { PatientListScreen() }
                .tabItem { Label("Patients", systemImage: "person.2") }

            NavigationStack { CaptureScreen() }
                .tabItem { Label("Capture", systemImage: "camera.viewfinder") }

            NavigationStack { MoreTab() }
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
        .tint(Theme.ink)
        .preferredColorScheme(.light)
    }
}
