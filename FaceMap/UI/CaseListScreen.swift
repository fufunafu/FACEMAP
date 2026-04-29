import SwiftUI
import SwiftData

struct CaseListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var store: CaseStore
    @Query(sort: \PatientCase.createdAt, order: .reverse) private var cases: [PatientCase]

    var body: some View {
        Group {
            if cases.isEmpty {
                ContentUnavailableView(
                    "No saved cases",
                    systemImage: "tray",
                    description: Text("Capture a face on the Capture tab and save it here.")
                )
            } else {
                List {
                    ForEach(cases) { c in
                        NavigationLink {
                            if let face = c.capturedFace {
                                AnalysisScreen(face: face, existingCase: c)
                            } else {
                                Text("Stored mesh is unreadable.")
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(c.label).font(.headline)
                                Text(c.createdAt, style: .date) +
                                Text(" · ") + Text(c.createdAt, style: .time)
                            }
                            .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { store.delete(cases[i]) }
                    }
                }
            }
        }
        .navigationTitle("Cases")
    }
}
