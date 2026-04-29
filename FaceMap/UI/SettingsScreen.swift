import SwiftUI
import LocalAuthentication

/// Per-practitioner preferences. Persisted in `UserDefaults`. None of these affect
/// the on-disk case store; they tune the analysis presentation only.
struct SettingsScreen: View {
    @AppStorage("biometricLockEnabled") private var biometricLock = false
    @AppStorage("targetThirdsToleranceBP") private var thirdsTolerance: Double = 0.05
    @AppStorage("targetFifthsToleranceBP") private var fifthsTolerance: Double = 0.10
    @AppStorage("targetGoldenToleranceBP") private var goldenTolerance: Double = 0.10
    @AppStorage("targetCanthalLow") private var canthalLow: Double = 4.0
    @AppStorage("targetCanthalHigh") private var canthalHigh: Double = 7.0
    @AppStorage("targetAsymmetryMM") private var asymmetryMM: Double = 1.5

    @State private var biometricUnavailableReason: String?

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            Form {
                Section {
                    Toggle("Lock with Face ID", isOn: Binding(
                        get: { biometricLock },
                        set: { setBiometricLock($0) }
                    ))
                    if let reason = biometricUnavailableReason {
                        Text(reason)
                            .font(Type.caption)
                            .foregroundStyle(Theme.inkMuted)
                    }
                } header: {
                    Text("Privacy").sectionHeaderStyle()
                } footer: {
                    Text("Off by default. When on, FaceMap re-authenticates with Face ID before opening saved cases.")
                        .font(Type.caption)
                }

                Section {
                    targetSlider("Facial thirds tolerance",
                                 value: $thirdsTolerance,
                                 range: 0.02...0.10,
                                 step: 0.01,
                                 format: pct)
                    targetSlider("Facial fifths tolerance",
                                 value: $fifthsTolerance,
                                 range: 0.05...0.20,
                                 step: 0.01,
                                 format: pct)
                    targetSlider("Golden ratio tolerance",
                                 value: $goldenTolerance,
                                 range: 0.05...0.20,
                                 step: 0.01,
                                 format: pct)
                    targetRangeSlider("Canthal tilt target",
                                      low: $canthalLow,
                                      high: $canthalHigh,
                                      range: 0...12,
                                      step: 0.5,
                                      unit: "°")
                    targetSlider("Asymmetry threshold",
                                 value: $asymmetryMM,
                                 range: 0.5...4.0,
                                 step: 0.1,
                                 format: { String(format: "%.1f mm", $0) })

                    Button("Reset to defaults", role: .destructive) {
                        thirdsTolerance = 0.05
                        fifthsTolerance = 0.10
                        goldenTolerance = 0.10
                        canthalLow  = 4.0
                        canthalHigh = 7.0
                        asymmetryMM = 1.5
                    }
                } header: {
                    Text("Target ranges").sectionHeaderStyle()
                } footer: {
                    Text("Tune severity thresholds to match your aesthetic norms. These overrides apply to future analyses; saved cases keep their original computed severities.")
                        .font(Type.caption)
                }

                Section {
                    Toggle("Cloud sync", isOn: .constant(false))
                        .disabled(true)
                    Text("Coming in Phase 2 — Sign in with Apple, Vercel-hosted backend, opt-in only.")
                        .font(Type.caption)
                        .foregroundStyle(Theme.inkMuted)
                } header: {
                    Text("Sync").sectionHeaderStyle()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkBiometricAvailability() }
    }

    private func pct(_ v: Double) -> String { String(format: "%.0f%%", v * 100) }

    @ViewBuilder
    private func targetSlider(_ title: String, value: Binding<Double>,
                              range: ClosedRange<Double>, step: Double,
                              format: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(Type.body)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func targetRangeSlider(_ title: String,
                                   low: Binding<Double>, high: Binding<Double>,
                                   range: ClosedRange<Double>, step: Double,
                                   unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(Type.body)
                Spacer()
                Text(String(format: "%.1f–%.1f%@",
                            low.wrappedValue, high.wrappedValue, unit))
                    .font(Type.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkDim)
            }
            HStack {
                Text("Low").font(Type.caption).foregroundStyle(Theme.inkMuted)
                Slider(value: low, in: range.lowerBound...high.wrappedValue, step: step)
            }
            HStack {
                Text("High").font(Type.caption).foregroundStyle(Theme.inkMuted)
                Slider(value: high, in: low.wrappedValue...range.upperBound, step: step)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Biometric

    private func checkBiometricAvailability() {
        let ctx = LAContext()
        var err: NSError?
        let ok = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
        if !ok {
            biometricUnavailableReason = "Face ID not available on this device"
            biometricLock = false
        } else {
            biometricUnavailableReason = nil
        }
    }

    private func setBiometricLock(_ on: Bool) {
        guard on else { biometricLock = false; return }
        // Confirm enrolment before persisting the preference.
        let ctx = LAContext()
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                          localizedReason: "Enable Face ID lock for FaceMap.") { ok, _ in
            DispatchQueue.main.async { self.biometricLock = ok }
        }
    }
}
