import SwiftUI

struct DisclaimerGate<Content: View>: View {
    @AppStorage("hasAcceptedDisclaimerV1") private var hasAccepted = false
    let content: () -> Content

    var body: some View {
        if hasAccepted {
            content()
        } else {
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
                            hasAccepted = true
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
    }
}

#Preview {
    DisclaimerGate { Text("App content").foregroundStyle(.white) }
        .preferredColorScheme(.light)
}
