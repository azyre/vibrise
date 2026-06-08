#if canImport(UIKit)
import SwiftUI
import UIKit

struct ShareCloseButton: View {
    let onClose: () -> Void

    var body: some View {
        GlassCircleButton(
            systemName: "xmark",
            action: onClose,
            iconSize: DesignTokens.Size.modalCloseIcon,
            iconWeight: .regular,
            frameSize: DesignTokens.Size.closeButton,
            foregroundColor: DesignTokens.Colors.primaryText,
            fillColor: DesignTokens.Colors.surface,
            strokeColor: DesignTokens.Colors.surfaceBorder,
            strokeWidth: DesignTokens.Border.regular
        )
    }
}

struct SharePreviewCard: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(1080.0 / 1352.0, contentMode: .fit)
            .frame(width: 280, height: 350.52)
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
    }
}

struct ShareActionButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.controlGap) {
                ZStack {
                    Image(systemName: systemImage)
                        .font(.system(size: DesignTokens.Size.modalCloseIcon, weight: .regular))
                        .opacity(isLoading ? 0 : 1)

                    if isLoading {
                        ProgressView()
                            .tint(DesignTokens.Colors.primaryText)
                            .scaleEffect(0.8)
                    }
                }
                .frame(width: DesignTokens.Size.modalCloseIcon, height: DesignTokens.Size.modalCloseIcon)

                Text(title)
                    .vibriseSatoshiText(size: 16, weight: .medium)
            }
            .foregroundStyle(DesignTokens.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .glassCapsuleChrome(
                height: DesignTokens.Size.primaryActionHeight,
                fillColor: DesignTokens.Colors.surface,
                strokeColor: DesignTokens.Colors.surfaceBorder,
                strokeWidth: DesignTokens.Border.regular
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct ShareToastOverlay: View {
    let message: String

    var body: some View {
        VStack {
            GlassToastView(message: message)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
    }
}
#endif
