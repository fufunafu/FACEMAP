import SwiftUI

/// FaceMap wordmark + Dr Andreas Nikolis attribution. Used on splash, disclaimer,
/// PDF export header, and as a small variant in nav headers.
struct BrandMark: View {
    enum Size { case large, medium, small }

    let size: Size

    init(_ size: Size = .medium) { self.size = size }

    var body: some View {
        VStack(spacing: spacing) {
            Text("FACEMAP")
                .font(wordmarkFont)
                .tracking(tracking)
                .foregroundStyle(Theme.ink)

            Rectangle()
                .fill(Theme.hairline)
                .frame(width: dividerWidth, height: 1)

            Text("by Dr Andreas Nikolis · MD, FRCSC")
                .font(captionFont)
                .foregroundStyle(Theme.inkDim)
        }
    }

    // MARK: - Size mapping

    private var wordmarkFont: Font {
        switch size {
        case .large:  return .system(size: 34, weight: .regular, design: .serif)
        case .medium: return .system(size: 22, weight: .regular, design: .serif)
        case .small:  return .system(size: 14, weight: .medium,  design: .serif)
        }
    }

    private var captionFont: Font {
        switch size {
        case .large:  return Type.caption
        case .medium: return Type.caption
        case .small:  return .system(size: 9)
        }
    }

    private var tracking: CGFloat {
        switch size {
        case .large:  return 4
        case .medium: return 2.5
        case .small:  return 1.5
        }
    }

    private var dividerWidth: CGFloat {
        switch size {
        case .large:  return 80
        case .medium: return 56
        case .small:  return 28
        }
    }

    private var spacing: CGFloat {
        switch size {
        case .large:  return 12
        case .medium: return 8
        case .small:  return 4
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        BrandMark(.large)
        BrandMark(.medium)
        BrandMark(.small)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.canvas)
    .preferredColorScheme(.light)
}
