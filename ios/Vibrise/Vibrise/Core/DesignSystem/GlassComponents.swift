import SwiftUI

struct GlassCircleButton: View {
    let systemName: String
    let action: () -> Void

    var iconSize: CGFloat = DesignTokens.Size.bodyIcon
    var iconWeight: Font.Weight = .regular
    var frameSize: CGFloat = DesignTokens.Size.toolbarButton
    var foregroundColor: Color = DesignTokens.Colors.primaryText
    var fillColor: Color = DesignTokens.Colors.surface
    var strokeColor: Color = DesignTokens.Colors.surfaceBorder
    var strokeWidth: CGFloat = DesignTokens.Border.regular
    var showsInnerShadow: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundStyle(foregroundColor)
                .frame(width: frameSize, height: frameSize)
                .background {
                    ZStack {
                        Circle()
                            .fill(fillColor)
                            .background(.ultraThinMaterial, in: Circle())

                        if showsInnerShadow {
                            Circle()
                                .inset(by: 1)
                                .stroke(Color.black.opacity(0.10), lineWidth: 8)
                                .blur(radius: 8)
                                .blendMode(.multiply)
                                .clipShape(Circle())
                        }
                    }
                }
                .overlay {
                    Circle()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                }
        }
        .buttonStyle(.plain)
    }
}

struct GlassToastView: View {
    let message: String
    var topPadding: CGFloat = DesignTokens.Spacing.large

    var body: some View {
        Text(message)
            .vibriseSatoshiText(size: 14, weight: .medium)
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .frame(height: DesignTokens.Size.toastHeight)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.28))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay {
                Capsule()
                    .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: DesignTokens.Border.regular)
            }
            .padding(.top, topPadding)
    }
}

private struct GlassCapsuleChromeModifier: ViewModifier {
    let height: CGFloat
    let fillColor: Color
    let strokeColor: Color
    let strokeWidth: CGFloat
    let showsInnerShadow: Bool

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .background {
                ZStack {
                    Capsule()
                        .fill(fillColor)
                        .background(.ultraThinMaterial, in: Capsule())

                    if showsInnerShadow {
                        Capsule()
                            .inset(by: 1)
                            .stroke(Color.black.opacity(0.10), lineWidth: 8)
                            .blur(radius: 8)
                            .blendMode(.multiply)
                            .clipShape(Capsule())
                    }
                }
            }
            .overlay {
                Capsule()
                    .stroke(strokeColor, lineWidth: strokeWidth)
            }
    }
}

extension View {
    func glassCapsuleChrome(
        height: CGFloat = DesignTokens.Size.toolbarButton,
        fillColor: Color = DesignTokens.Colors.surface,
        strokeColor: Color = DesignTokens.Colors.surfaceBorder,
        strokeWidth: CGFloat = DesignTokens.Border.regular,
        showsInnerShadow: Bool = false
    ) -> some View {
        modifier(
            GlassCapsuleChromeModifier(
                height: height,
                fillColor: fillColor,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
                showsInnerShadow: showsInnerShadow
            )
        )
    }
}
