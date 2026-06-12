import SwiftUI

/// Amber warning shown wherever metric outputs appear while this device's landmark
/// indices are still the uncalibrated placeholders. Callers wrap it in a
/// `NavigationLink` to `CalibrationScreen` so the tap-to-calibrate affordance works.
struct CalibrationWarningBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Type.control)
                .foregroundStyle(Theme.warning)

            Text(DisclaimerCopy.uncalibratedWarning)
                .font(Type.caption)
                .foregroundStyle(Theme.warningInk)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(Type.labelSmall)
                .foregroundStyle(Theme.warning)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Theme.warningBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Theme.warning.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens landmark calibration")
    }
}
