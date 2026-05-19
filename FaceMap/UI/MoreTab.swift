import SwiftUI

/// "More" tab — About / Settings / Calibration explainer / Disclaimer re-read.
struct MoreTab: View {
    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            List {
                Section {
                    NavigationLink {
                        AboutScreen()
                    } label: {
                        Label("About Dr Andreas Nikolis", systemImage: "person.fill")
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Practitioner").sectionHeaderStyle()
                }

                Section {
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .listRowBackground(Theme.surface)

                    NavigationLink {
                        CalibrationExplainerScreen()
                    } label: {
                        Label("Landmark calibration", systemImage: "scope")
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("App").sectionHeaderStyle()
                }

                Section {
                    NavigationLink {
                        DisclaimerReadScreen()
                    } label: {
                        Label("Disclaimer", systemImage: "doc.plaintext")
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Legal").sectionHeaderStyle()
                } footer: {
                    Text("FaceMap by Dr Andreas Nikolis · v0.2.0")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 16)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
        }
        .navigationTitle("More")
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

// MARK: - About (placeholder copy until Dr Nikolis supplies real bio)

struct AboutScreen: View {
    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BrandMark(.large)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)

                    Text("Dr Andreas Nikolis")
                        .font(Type.displayMedium)
                        .foregroundStyle(Theme.ink)
                    Text("MD, FRCSC")
                        .font(Type.callout)
                        .foregroundStyle(Theme.inkDim)

                    Text(DisclaimerCopy.aboutNikolis)
                        .font(Type.body)
                        .foregroundStyle(Theme.inkDim)
                        .padding(.top, 8)

                    Divider().padding(.vertical, 8)

                    Text("THE FOUR-DOMAIN FRAMEWORK").sectionHeaderStyle()
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(FaceDomain.allCases) { d in
                            HStack(alignment: .top, spacing: 12) {
                                Circle().fill(d.hue).frame(width: 10, height: 10)
                                    .padding(.top, 6)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(d.displayName)
                                        .font(Type.body.weight(.medium))
                                        .foregroundStyle(Theme.ink)
                                    Text(domainBlurb(d))
                                        .font(Type.caption)
                                        .foregroundStyle(Theme.inkDim)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func domainBlurb(_ d: FaceDomain) -> String {
        switch d {
        case .skinQuality: return "Loss of radiance, glow, and firmness."
        case .facialShape: return "Sagging and volume loss across midface, lower face, and jawline."
        case .proportions: return "Facial thirds and fifths, golden-ratio relationships."
        case .symmetry:    return "Lateral pair asymmetry and canthal tilt."
        case .expression:  return "Static lines and dynamic distortion at rest and on animation."
        }
    }
}

// MARK: - Calibration explainer

struct CalibrationExplainerScreen: View {
    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Landmark calibration")
                        .font(Type.displayMedium)
                        .foregroundStyle(Theme.ink)

                    Text("ARKit's face mesh has fixed topology — a given anatomical landmark always maps to the same vertex index across devices. FaceMap ships with reference indices that should be confirmed against your own captures before clinical interpretation.")
                        .font(Type.body)
                        .foregroundStyle(Theme.inkDim)

                    Text("HOW TO RUN").sectionHeaderStyle()
                    VStack(alignment: .leading, spacing: 8) {
                        labelledStep("1.", "Open a captured case from the Patients tab.")
                        labelledStep("2.", "Tap the scope icon in the Analysis toolbar.")
                        labelledStep("3.", "Tap each named landmark on the rendered mesh in turn.")
                        labelledStep("4.", "Save when finished — calibrated indices override the defaults from then on.")
                    }
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))

                    Text("Calibrated values persist on this device only. They do not affect saved cases, only future analyses.")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.top, 4)
                }
                .padding(24)
            }
        }
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labelledStep(_ marker: String, _ body: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(marker)
                .font(Type.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 22, alignment: .leading)
            Text(body)
                .font(Type.body)
                .foregroundStyle(Theme.inkDim)
        }
    }
}

struct DisclaimerReadScreen: View {
    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A planning aid for licensed practitioners")
                        .font(Type.displayMedium)
                        .foregroundStyle(Theme.ink)

                    Text(DisclaimerCopy.firstLaunchBody)
                        .font(Type.body)
                        .foregroundStyle(Theme.inkDim)

                    Text("Developed in collaboration with Dr Andreas Nikolis, MD, FRCSC.")
                        .font(Type.callout)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
