import SwiftUI

struct DisclaimerGate<Content: View>: View {
    @AppStorage("hasAcceptedDisclaimerV1") private var hasAccepted = false
    let content: () -> Content

    var body: some View {
        if hasAccepted {
            content()
        } else {
            VStack(spacing: 24) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text(DisclaimerCopy.firstLaunchTitle)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                ScrollView {
                    Text(DisclaimerCopy.firstLaunchBody)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: 320)
                Button {
                    hasAccepted = true
                } label: {
                    Text("I am a licensed practitioner — continue")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
    }
}
