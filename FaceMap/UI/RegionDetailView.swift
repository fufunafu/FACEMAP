import SwiftUI

/// Shown when the user taps a flagged region. Lists every metric that contributed to the flag
/// with its measured value and target.
struct RegionDetailView: View {
    let region: FacialRegion
    let allResults: [MetricResult]

    private var contributing: [MetricResult] {
        allResults.filter { !$0.isWithinTarget && $0.regions.contains(region) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if contributing.isEmpty {
                        Text("No metrics flagged this region.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(contributing, id: \.metricId) { r in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.metricName).font(.headline)
                                if let n = r.notes {
                                    Text(n).font(.caption).foregroundStyle(.secondary)
                                }
                                HStack {
                                    Circle().fill(r.severity.color).frame(width: 8, height: 8)
                                    Text(r.severity.rawValue.capitalized)
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text(DisclaimerCopy.analysisFooter)
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
