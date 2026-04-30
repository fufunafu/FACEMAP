import SwiftUI

/// Pushed view shown when the practitioner taps a `CategoryRow` in the analysis
/// overview. Renders only the metrics in the selected `FaceDomain`, plus the mesh
/// tinted with that domain's flagged regions and (for `AsymmetryMetric`) the
/// divergent-pair chart.
struct DomainDetailScreen: View {
    let domain: FaceDomain
    let face: CapturedFace
    let allResults: [MetricResult]
    /// Region severities pre-computed by the parent screen (already merged across metrics).
    let regionSeverity: [FacialRegion: MetricResult.Severity]
    let regionDomain: [FacialRegion: FaceDomain]
    /// Same formatter `AnalysisScreen` uses, threaded through so display strings stay consistent.
    let valueFormatter: (MetricResult) -> String

    @State private var selectedRegion: FacialRegion?
    @StateObject private var meshController = FaceMeshController()
    @State private var showingFullscreen = false

    /// Only metrics whose domain matches.
    private var inDomain: [MetricResult] {
        allResults.filter { $0.domain == domain }
    }

    /// Region severities filtered to those flagged by metrics in this domain.
    private var domainRegionSeverity: [FacialRegion: MetricResult.Severity] {
        let domainRegions = Set(inDomain.flatMap { $0.regions })
        return regionSeverity.filter { domainRegions.contains($0.key) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                meshCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if inDomain.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(inDomain, id: \.metricId) { r in
                            metricRow(for: r)
                            if r.metricId == AsymmetryMetric.id {
                                AsymmetryDivergentChart(
                                    result: r,
                                    pairs: AsymmetryDivergentChart.computePairs(
                                        from: AnalyzableFace(face)
                                    )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                DisclaimerBanner()
                    .padding(.top, 8)
            }
            .padding(.bottom, 16)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(domain.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRegion) { region in
            RegionDetailView(region: region, allResults: allResults)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingFullscreen) {
            MeshFullScreen(
                face: face,
                regionSeverity: domainRegionSeverity,
                regionDomain: regionDomain
            )
        }
    }

    // MARK: - Mesh card

    private var meshCard: some View {
        Button { showingFullscreen = true } label: {
            ZStack(alignment: .bottomTrailing) {
                FaceMeshOverlay(
                    face: face,
                    regionSeverity: domainRegionSeverity,
                    regionDomain: regionDomain,
                    controller: meshController,
                    interactive: false,
                    backgroundColor: UIColor(Theme.surfaceRaised)
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(8)
                    .background(.regularMaterial, in: Circle())
                    .padding(10)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open 3D viewer fullscreen")
    }

    // MARK: - Metric row + drill-in

    private func metricRow(for r: MetricResult) -> some View {
        Button {
            // Open the first implicated region of this metric, if any. Lets the user
            // jump straight from a flagged metric into its region breakdown.
            if let firstRegion = r.regions.first(where: { regionSeverity[$0] != nil }) ?? r.regions.first {
                selectedRegion = firstRegion
            }
        } label: {
            MetricRow(
                result: r,
                domain: r.domain,
                valueText: valueFormatter(r),
                trailingChevron: !r.regions.isEmpty
            )
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 28))
                .foregroundStyle(Theme.inkMuted)
            Text("No metrics for this domain yet.")
                .font(Type.body)
                .foregroundStyle(Theme.ink)
            Text("Coming in v0.3.")
                .font(Type.caption)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}
