import SwiftUI
import simd

/// Annotation flow for the Analysis screen. v0.2 approach: practitioner picks an anatomical
/// region from a structured list; the pin is placed at that region's vertex-cluster centroid
/// in face-local mesh coordinates. This is more clinically meaningful than free-tap and
/// avoids the hit-testing complexity of 3D ray-casting against a generated MeshResource.
///
/// Pins are persisted on `PatientCase.annotationsJSON` and re-render across sessions.
struct AnnotationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let face: CapturedFace
    /// Existing pins, in chronological order.
    @Binding var pins: [AnnotationPin]
    /// Called when the pin set changes (caller persists).
    var onChange: () -> Void

    @State private var stage: Stage = .list
    @State private var selectedRegion: FacialRegion?
    @State private var selectedDomain: FaceDomain?
    @State private var selectedSeverity: MetricResult.Severity = .moderate
    @State private var label: String = ""

    private enum Stage {
        case list, pickRegion, addLabel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.canvas.ignoresSafeArea()
                content
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(stage == .list ? "Done" : "Back") {
                        if stage == .list { dismiss() }
                        else { stage = .list }
                    }
                    .foregroundStyle(Theme.ink)
                }
                if stage == .list {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            stage = .pickRegion
                        } label: {
                            Image(systemName: "plus")
                        }
                        .foregroundStyle(Theme.ink)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var navTitle: String {
        switch stage {
        case .list:       return "Annotation pins"
        case .pickRegion: return "Pick region"
        case .addLabel:   return "Pin details"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .list:       pinList
        case .pickRegion: regionPicker
        case .addLabel:   labelEntry
        }
    }

    // MARK: - Pin list

    private var pinList: some View {
        ScrollView {
            VStack(spacing: 8) {
                if pins.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.inkDim)
                        Text("No pins yet")
                            .font(Type.titleLarge)
                            .foregroundStyle(Theme.ink)
                        Text("Tap + to drop a pin on a flagged region.")
                            .font(Type.callout)
                            .foregroundStyle(Theme.inkDim)
                    }
                    .padding(40)
                } else {
                    ForEach(pins) { pin in pinRow(pin) }
                }
            }
            .padding(16)
        }
    }

    private func pinRow(_ pin: AnnotationPin) -> some View {
        HStack(spacing: 12) {
            if let d = pin.domain {
                SeverityDot(domain: d, severity: pin.severity ?? .moderate, size: 12)
                    .padding(.top, 4)
            } else {
                Circle().fill(Theme.ink).frame(width: 12, height: 12).padding(.top, 4)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(pin.label.isEmpty ? "(no label)" : pin.label)
                    .font(Type.body)
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    if let d = pin.domain { DomainBadge(domain: d) }
                    Text(pin.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                }
            }
            Spacer()
            Button(role: .destructive) {
                pins.removeAll { $0.id == pin.id }
                onChange()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.domainSymmetry)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }

    // MARK: - Region picker

    private var regionPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(regionGroups, id: \.0) { group, regions in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group).sectionHeaderStyle()
                            .padding(.horizontal, 16)
                        VStack(spacing: 4) {
                            ForEach(regions, id: \.self) { r in
                                Button {
                                    selectedRegion = r
                                    selectedDomain = .symmetry  // default until user picks
                                    label = ""
                                    stage = .addLabel
                                } label: {
                                    HStack {
                                        Text(r.displayName)
                                            .font(Type.body)
                                            .foregroundStyle(Theme.ink)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Theme.inkMuted)
                                    }
                                    .padding(12)
                                    .background(Theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var regionGroups: [(String, [FacialRegion])] {
        [
            ("UPPER FACE",  [.forehead, .templeL, .templeR, .browL, .browR]),
            ("PERIORBITAL", [.tearTroughL, .tearTroughR]),
            ("MIDFACE",     [.midfaceL, .midfaceR, .nasolabialL, .nasolabialR]),
            ("PERIORAL",    [.lipUpper, .lipLower, .perioral]),
            ("LOWER FACE",  [.marionetteL, .marionetteR, .chin,
                             .prejowlL, .prejowlR, .jawlineL, .jawlineR]),
        ]
    }

    // MARK: - Label entry

    private var labelEntry: some View {
        Form {
            if let r = selectedRegion {
                Section {
                    Text(r.displayName)
                        .font(Type.body)
                        .foregroundStyle(Theme.ink)
                } header: {
                    Text("Region").sectionHeaderStyle()
                }
            }

            Section {
                TextField("Label (no PII)", text: $label)
            } header: {
                Text("Label").sectionHeaderStyle()
            }

            Section {
                Picker("Domain", selection: Binding(
                    get: { selectedDomain ?? .symmetry },
                    set: { selectedDomain = $0 }
                )) {
                    ForEach(FaceDomain.allCases) { d in
                        Text(d.displayName).tag(d)
                    }
                }
                Picker("Severity", selection: $selectedSeverity) {
                    Text("Mild").tag(MetricResult.Severity.mild)
                    Text("Moderate").tag(MetricResult.Severity.moderate)
                    Text("Significant").tag(MetricResult.Severity.significant)
                }
            }

            Section {
                Button {
                    addPin()
                } label: {
                    Text("Add pin")
                }
                .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
    }

    private func addPin() {
        guard let r = selectedRegion else { return }
        let pos = regionCentroid(r) ?? SIMD3<Float>(0, 0, 0)
        let pin = AnnotationPin(
            position: pos,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            severity: selectedSeverity,
            domain: selectedDomain
        )
        pins.append(pin)
        onChange()
        // Reset and back to list
        label = ""
        selectedRegion = nil
        selectedDomain = nil
        selectedSeverity = .moderate
        stage = .list
    }

    private func regionCentroid(_ r: FacialRegion) -> SIMD3<Float>? {
        guard let indices = FaceLandmarkIndices.regionVertices[r] else { return nil }
        let verts = face.vertices
        var sum = SIMD3<Float>(repeating: 0)
        var n = 0
        for i in indices where i >= 0 && i < verts.count {
            sum += verts[i]
            n += 1
        }
        return n > 0 ? sum / Float(n) : nil
    }
}
