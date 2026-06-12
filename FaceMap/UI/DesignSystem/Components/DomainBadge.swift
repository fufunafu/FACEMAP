import SwiftUI

/// Tiny domain chip — a coloured dot + the domain name in small caps.
/// Used on metric rows and region pills to keep the four-domain framework
/// visible everywhere the metric data appears.
struct DomainBadge: View {
    let domain: FaceDomain

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(domain.hue)
                .frame(width: 6, height: 6)
            Text(short)
                .font(Type.labelSmall)
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Theme.inkDim)
        }
    }

    private var short: String {
        switch domain {
        case .skinQuality: return "Skin"
        case .facialShape: return "Shape"
        case .proportions: return "Proportions"
        case .symmetry:    return "Symmetry"
        case .expression:  return "Expression"
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(FaceDomain.allCases) { DomainBadge(domain: $0) }
    }
    .padding()
    .background(Theme.canvas)
    .preferredColorScheme(.light)
}
