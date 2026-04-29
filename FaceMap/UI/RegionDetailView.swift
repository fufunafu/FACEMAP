import SwiftUI

/// Shown when the user taps a flagged region. Lists every metric that contributed
/// to the flag with its measured value and target.
struct RegionDetailView: View {
    let region: FacialRegion
    let allResults: [MetricResult]

    private var contributing: [MetricResult] {
        allResults.filter { !$0.isWithinTarget && $0.regions.contains(region) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if contributing.isEmpty {
                            Text("No metrics flagged this region.")
                                .font(Type.body)
                                .foregroundStyle(Theme.inkDim)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(contributing, id: \.metricId) { r in
                                HStack(alignment: .top, spacing: 12) {
                                    SeverityDot(domain: r.domain, severity: r.severity, size: 10)
                                        .padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(r.metricName)
                                                .font(Type.metricName)
                                                .foregroundStyle(Theme.ink)
                                            Spacer()
                                            DomainBadge(domain: r.domain)
                                        }
                                        Text(r.severity.rawValue.capitalized)
                                            .font(Type.caption.monospacedDigit())
                                            .foregroundStyle(Theme.inkDim)
                                        if let n = r.notes {
                                            Text(n)
                                                .font(Type.caption)
                                                .foregroundStyle(Theme.inkMuted)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                            }
                        }

                        Text(DisclaimerCopy.analysisFooter)
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
