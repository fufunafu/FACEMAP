import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: CaseStore

    /// Presents the store's most recent persistence failure; dismissing clears it.
    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { store.lastSaveError != nil },
            set: { if !$0 { store.lastSaveError = nil } }
        )
    }

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
        .alert("Could not save changes", isPresented: saveErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.lastSaveError ?? "Try again.")
        }
    }
}
