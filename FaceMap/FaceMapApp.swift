import SwiftUI
import SwiftData

@main
struct FaceMapApp: App {
    let container: ModelContainer
    let store: CaseStore

    init() {
        let c: ModelContainer
        do {
            c = try ModelContainer(for: PatientCase.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
        self.container = c
        self.store = CaseStore(context: c.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            DisclaimerGate {
                ContentView().environmentObject(store)
            }
        }
        .modelContainer(container)
    }
}
