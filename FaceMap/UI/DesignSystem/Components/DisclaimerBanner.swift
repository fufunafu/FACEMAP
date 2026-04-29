import SwiftUI

/// Slim persistent banner shown beneath every analysis-context surface.
/// Keeps the regulatory framing visible without dominating the layout.
struct DisclaimerBanner: View {
    var body: some View {
        Text(DisclaimerCopy.analysisFooter)
            .font(Type.caption)
            .foregroundStyle(Theme.inkMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
    }
}
