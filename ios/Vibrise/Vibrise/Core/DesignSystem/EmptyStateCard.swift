import SwiftUI

struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    var height: CGFloat = 220

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .vibriseSatoshiText(size: 24, weight: .medium)

            Text(subtitle)
                .vibriseSatoshiText(size: 15, weight: .regular, color: DesignTokens.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(DesignTokens.Colors.surface)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous))
    }
}
