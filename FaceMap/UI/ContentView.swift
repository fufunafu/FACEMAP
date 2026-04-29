import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { CaptureScreen() }
                .tabItem { Label("Capture", systemImage: "camera.viewfinder") }

            NavigationStack { CaseListScreen() }
                .tabItem { Label("Cases", systemImage: "tray.full") }
        }
    }
}
