import SwiftUI

/// Amber warning shown wherever metric outputs appear while this device's landmark
/// indices are still the uncalibrated placeholders. Callers wrap it in a
/// `NavigationLink` to `CalibrationScreen` so the tap-to-calibrate affordance works.
struct CalibrationWarningBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: 0xB45309))

            Text(DisclaimerCopy.uncalibratedWarning)
                .font(Type.caption)
                .foregroundStyle(Color(hex: 0x78350F))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xB45309))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(hex: 0xFEF3C7))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .stroke(Color(hex: 0xB45309).opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens landmark calibration")
    }
}
