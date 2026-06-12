import SwiftUI

// MARK: - Versioned disclaimer acceptance

/// Versioning for disclaimer acceptance. Lives outside `DisclaimerGate` because
/// that type is generic and Swift forbids static stored properties on generic types.
enum DisclaimerAcceptance {
    /// Bump whenever `DisclaimerCopy.firstLaunchBody` materially changes.
    /// Any user whose stored accepted version is below this value is
    /// re-presented the full disclaimer gate on next launch.
    static let disclaimerVersion = 2
}

struct DisclaimerGate<Content: View>: View {
    /// Legacy unversioned flag from v0.x builds. Still written on acceptance
    /// for backward compatibility (older builds sharing the container read it).
    @AppStorage("hasAcceptedDisclaimerV1") private var hasAcceptedLegacy = false

    /// Versioned acceptance record. 0 = never recorded.
    @AppStorage("disclaimerAcceptedVersion") private var acceptedVersion = 0

    /// Acceptance timestamp as timeIntervalSince1970 (@AppStorage has no Date support).
    @AppStorage("disclaimerAcceptedAt") private var acceptedAt = 0.0

    /// Whether the 3-card first-run intro has been shown (or skipped).
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    /// Onboarding is presented only as a direct consequence of a first-time
    /// acceptance in this session — never on re-acceptance after a version bump.
    @State private var showOnboarding = false

    let content: () -> Content

    /// Migration mapping: a device that has only the legacy
    /// `hasAcceptedDisclaimerV1` bool set is treated as having accepted
    /// version 1. Intended behavior: such a device does NOT re-see the gate
    /// while `disclaimerVersion == 1`, and sees exactly one re-presentation
    /// now that the version is 2 (the disclaimer copy has materially changed
    /// once since the unversioned flag was introduced).
    private var effectiveAcceptedVersion: Int {
        if acceptedVersion > 0 { return acceptedVersion }
        return hasAcceptedLegacy ? 1 : 0
    }

    private var needsAcceptance: Bool {
        effectiveAcceptedVersion < DisclaimerAcceptance.disclaimerVersion
    }

    var body: some View {
        if needsAcceptance {
            disclaimerScreen
        } else if showOnboarding {
            OnboardingCards {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        } else {
            content()
        }
    }

    // MARK: Disclaimer screen

    private var disclaimerScreen: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 24)

                BrandMark(.large)

                Text("A planning aid for licensed practitioners")
                    .font(Type.displayMedium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if effectiveAcceptedVersion > 0 {
                            Text("These terms have been updated since you last accepted them. Please review and confirm again.")
                                .font(Type.captionStrong)
                                .foregroundStyle(Theme.ink)
                        }

                        Text(DisclaimerCopy.firstLaunchBody)
                            .font(Type.body)
                            .foregroundStyle(Theme.inkDim)
                            .multilineTextAlignment(.leading)

                        Text("Developed in collaboration with Dr Andreas Nikolis, MD, FRCSC.")
                            .font(Type.callout)
                            .foregroundStyle(Theme.ink)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 320)

                VStack(spacing: 12) {
                    Button {
                        accept()
                    } label: {
                        Text("I am a licensed practitioner — continue")
                    }
                    .buttonStyle(.primary)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .preferredColorScheme(.light)
    }

    private func accept() {
        let isFirstAcceptance = effectiveAcceptedVersion == 0
        acceptedVersion = DisclaimerAcceptance.disclaimerVersion
        acceptedAt = Date().timeIntervalSince1970
        hasAcceptedLegacy = true  // keep legacy key written for backward compatibility

        // Onboarding cards appear after first-time acceptance only — users
        // re-accepting after a version bump go straight back into the app.
        if isFirstAcceptance && !hasSeenOnboarding {
            showOnboarding = true
        }
    }
}

// MARK: - First-run onboarding cards

/// Three-card intro shown once, immediately after first-time disclaimer
/// acceptance. Skippable at any point; purely descriptive — it explains how
/// the instrument is organised, never what to treat.
private struct OnboardingCards: View {
    let onFinish: () -> Void
    @State private var page = 0

    private static let lastPage = 2

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(Type.callout)
                        .foregroundStyle(Theme.inkDim)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                TabView(selection: $page) {
                    fasCard.tag(0)
                    captureCard.tag(1)
                    calibrationCard.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 20)

                Button {
                    if page < Self.lastPage {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(page < Self.lastPage ? "Next" : "Get started")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.light)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...Self.lastPage, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.ink : Theme.inkMuted.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
    }

    // MARK: Card 1 — The Facial Assessment Scale

    private var fasCard: some View {
        OnboardingCard(
            title: "The Facial Assessment Scale",
            message: "FaceMap organises findings into five FAS facets — Skin Quality, Facial Shape, Proportions, Symmetry, and Expression. Each facet appears as a sector of the aesthetic wheel, and severity is shown by ring depth, not a score."
        ) {
            AestheticWheel(resultsByDomain: [:], diameter: 200)
        }
    }

    // MARK: Card 2 — Three-pose capture

    private var captureCard: some View {
        OnboardingCard(
            title: "Three-pose capture",
            message: "Each visit captures a frontal TrueDepth scan and two oblique (±30°) scans, plus clinical reference photos. The app coaches head position automatically — just follow the on-screen prompts."
        ) {
            HStack(spacing: 28) {
                poseGlyph(label: "−30°")
                poseGlyph(label: "Frontal", emphasized: true)
                poseGlyph(label: "+30°")
            }
        }
    }

    private func poseGlyph(label: String, emphasized: Bool = false) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "faceid")
                .font(.system(size: emphasized ? 52 : 40, weight: .light))
                .foregroundStyle(emphasized ? Theme.ink : Theme.inkDim)
            Text(label)
                .font(Type.caption)
                .foregroundStyle(Theme.inkDim)
        }
    }

    // MARK: Card 3 — Calibration

    private var calibrationCard: some View {
        OnboardingCard(
            title: "Calibrate once for meaningful values",
            message: "Metric values are not anatomically meaningful until landmark indices are calibrated on a captured case. Open an analysis and tap the scope icon in the toolbar to calibrate. Until then, a warning banner appears on every analysis."
        ) {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: Theme.hairlineWidth)
                    .frame(width: 140, height: 140)
                Image(systemName: "scope")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

/// Shared layout for a single onboarding page: illustration, serif title, body copy.
private struct OnboardingCard<Illustration: View>: View {
    let title: String
    let message: String
    @ViewBuilder let illustration: Illustration

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            illustration
                .frame(height: 220)

            Text(title)
                .font(Type.displayMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)

            Text(message)
                .font(Type.body)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    DisclaimerGate { Text("App content").foregroundStyle(.white) }
        .preferredColorScheme(.light)
}
