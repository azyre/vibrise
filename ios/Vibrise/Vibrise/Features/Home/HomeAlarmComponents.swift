import SwiftUI

struct AlarmCard: View {
    let alarm: Alarm
    let onTest: () -> Void
    let onTap: () -> Void
    let onToggle: (Bool) -> Void
    let highlightStrokeOpacity: CGFloat
    let highlightBlurRadius: CGFloat
    let highlightStrokeWidth: CGFloat
    let baseStrokeOpacity: CGFloat

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Button {
                        onTest()
                    } label: {
                        Text("Test")
                            .vibriseSatoshiText(size: 13)
                            .padding(.horizontal, DesignTokens.Spacing.small)
                            .frame(height: 32)
                            .background(DesignTokens.Colors.surface)
                            .overlay {
                                Capsule()
                                    .stroke(DesignTokens.Colors.surfaceBorder, lineWidth: 1)
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { alarm.isEnabled },
                        set: onToggle
                    ))
                    .labelsHidden()
                    .tint(.white.opacity(0.7))
                }

                Text(alarm.displayTime)
                    .font(DesignTokens.Typography.mavenProFont(size: 64))
                    .tracking(DesignTokens.Typography.tracking(for: 64))
                    .foregroundStyle(DesignTokens.Colors.primaryText)
                    .padding(.top, DesignTokens.Spacing.headerToContent)

                HStack(spacing: DesignTokens.Spacing.controlGap) {
                    let orderedDays = [1, 2, 3, 4, 5, 6, 0]

                    ForEach(Array(orderedDays.enumerated()), id: \.offset) { _, dayIndex in
                        let label = Alarm.dayShortLabels[dayIndex]
                        let isSelected = alarm.repeatDays.contains(dayIndex)

                        Text(label)
                            .font(DesignTokens.Typography.satoshiFont(size: 12))
                            .fontWeight(isSelected ? .medium : .regular)
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.2))
                            .blendMode(.plusLighter)
                            .frame(width: DesignTokens.Size.dayChip, height: DesignTokens.Size.dayChip)
                            .background {
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.10) : Color.black.opacity(0.20))
                                    .blendMode(isSelected ? .plusLighter : .softLight)
                            }
                    }
                }
                .padding(.top, DesignTokens.Spacing.small)
            }
            .padding(DesignTokens.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .homeMaterialChrome(
                RoundedRectangle(
                    cornerRadius: DesignTokens.CornerRadius.card,
                    style: .continuous
                ),
                highlightStrokeOpacity: highlightStrokeOpacity,
                highlightBlurRadius: highlightBlurRadius,
                highlightStrokeWidth: highlightStrokeWidth,
                baseStrokeOpacity: baseStrokeOpacity
            )
            .opacity(alarm.isEnabled ? 1 : 0.7)
        }
        .buttonStyle(.plain)
    }
}

struct VibriseCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: DesignTokens.Size.bodyIcon, weight: .regular))
                .foregroundStyle(DesignTokens.Colors.primaryText)
                .frame(
                    width: DesignTokens.Size.toolbarButton,
                    height: DesignTokens.Size.toolbarButton
                )
                .homeMaterialChrome(
                    Circle(),
                    highlightStrokeOpacity: DesignTokens.Chrome.homeHighlightStrokeOpacity,
                    highlightBlurRadius: DesignTokens.Chrome.homeHighlightBlurRadius,
                    highlightStrokeWidth: DesignTokens.Chrome.homeHighlightStrokeWidth,
                    baseStrokeOpacity: DesignTokens.Chrome.homeBaseStrokeOpacity
                )
        }
        .buttonStyle(.plain)
    }
}

struct HomeMaterialChromeModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let fillOpacity: CGFloat
    let highlightStrokeOpacity: CGFloat
    let highlightBlurRadius: CGFloat
    let highlightStrokeWidth: CGFloat
    let baseStrokeOpacity: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(fillOpacity), in: shape)
            .overlay {
                shape
                    .inset(by: 1)
                    .stroke(Color.black.opacity(0.10), lineWidth: 6)
                    .blur(radius: 6)
                    .blendMode(.multiply)
                    .clipShape(shape)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(baseStrokeOpacity), lineWidth: 1)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(highlightStrokeOpacity), lineWidth: highlightStrokeWidth)
                    .blur(radius: highlightBlurRadius)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: UnitPoint(x: 0, y: 0),
                            endPoint: UnitPoint(x: 0.15, y: 0.5)
                        )
                    )
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(highlightStrokeOpacity), lineWidth: highlightStrokeWidth)
                    .blur(radius: highlightBlurRadius)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .white],
                            startPoint: UnitPoint(x: 0.9, y: 0.7),
                            endPoint: UnitPoint(x: 1, y: 1)
                        )
                    )
            }
            .clipShape(shape)
    }
}

extension View {
    func homeMaterialChrome<S: InsettableShape>(
        _ shape: S,
        fillOpacity: CGFloat = 0.05,
        highlightStrokeOpacity: CGFloat = 0.5,
        highlightBlurRadius: CGFloat = 0.5,
        highlightStrokeWidth: CGFloat = 1.25,
        baseStrokeOpacity: CGFloat = 0.05
    ) -> some View {
        modifier(
            HomeMaterialChromeModifier(
                shape: shape,
                fillOpacity: fillOpacity,
                highlightStrokeOpacity: highlightStrokeOpacity,
                highlightBlurRadius: highlightBlurRadius,
                highlightStrokeWidth: highlightStrokeWidth,
                baseStrokeOpacity: baseStrokeOpacity
            )
        )
    }
}
