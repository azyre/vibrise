import SwiftUI

enum DesignTokens {
    enum Colors {
        static let backgroundTop = Color(red: 0.05, green: 0.05, blue: 0.09)
        static let backgroundBottom = Color(red: 0.10, green: 0.08, blue: 0.14)
        static let overlayScrim = Color.black.opacity(0.40)
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.60)
        static let tertiaryText = Color.white.opacity(0.32)
        static let surface = Color.white.opacity(0.08)
        static let surfaceBorder = Color.white.opacity(0.12)
        static let surfacePressed = Color.white.opacity(0.18)
    }

    enum Typography {
        static let mavenPro = "MavenPro-Regular"
        static let satoshi = "Satoshi Variable"
        static let trackingRatio: CGFloat = -0.04

        static func mavenProFont(size: CGFloat) -> Font {
            .custom(mavenPro, size: size)
        }

        static func satoshiFont(size: CGFloat) -> Font {
            .custom(satoshi, size: size)
        }

        static func tracking(for size: CGFloat) -> CGFloat {
            size * trackingRatio
        }

        /// Satoshi line spacing: <20pt → 150% line height, >=20pt → 120% line height
        static func satoshiLineSpacing(for size: CGFloat) -> CGFloat {
            let ratio: CGFloat = size < 20 ? 1.5 : 1.2
            return size * ratio - size
        }
    }

    enum CornerRadius {
        static let card: CGFloat = 24
        static let media: CGFloat = 16
        static let track: CGFloat = 22
        static let thumbnail: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screenPadding: CGFloat = 24
        static let screenTopCompact: CGFloat = 28
        static let screenBottomTight: CGFloat = 8
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 32
        static let hero: CGFloat = 60
        static let modalCloseTopInset: CGFloat = 62
        static let alarmEditorWeekdayToAction: CGFloat = 100
        static let homeHeaderTopInset: CGFloat = 122

        // Semantic aliases
        static let pageHorizontal: CGFloat = screenPadding
        static let pageTop: CGFloat = screenTopCompact
        static let pageBottom: CGFloat = xLarge
        static let headerToContent: CGFloat = hero
        static let controlGap: CGFloat = xSmall
        static let cardGap: CGFloat = small
    }

    enum Size {
        static let iconButton: CGFloat = 48
        static let iconSmall: CGFloat = 18
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let primaryButtonHeight: CGFloat = 60
        static let alarmEditorActionWidth: CGFloat = 345
        static let toastHeight: CGFloat = 40
        static let dayChip: CGFloat = 28
        static let dayPicker: CGFloat = 60
        static let wheelWidth: CGFloat = 150
        static let wheelHeight: CGFloat = 320
        static let pickerSelectionWidth: CGFloat = wheelWidth
        static let pickerSelectionHeight: CGFloat = 76
        static let pickerRowStep: CGFloat = 62
        static let pickerSeparatorSize: CGFloat = 48
        static let pickerValueSize: CGFloat = 36
        static let pickerAdjacentValueSize: CGFloat = 40
        static let pickerSelectedValueSize: CGFloat = 48

        // Semantic aliases
        static let closeButton: CGFloat = iconButton
        static let toolbarButton: CGFloat = iconButton
        static let bodyIcon: CGFloat = iconMedium
        static let smallIcon: CGFloat = iconSmall
        static let modalCloseIcon: CGFloat = iconLarge
        static let primaryActionHeight: CGFloat = primaryButtonHeight
        static let weekdaySelector: CGFloat = dayPicker
        static let pickerWidth: CGFloat = wheelWidth
        static let pickerHeight: CGFloat = wheelHeight
    }

    enum Border {
        static let glassThin: CGFloat = 0.33
        static let regular: CGFloat = 1
    }

    enum Motion {
        static let toastDurationMs: UInt64 = 1400
    }

    enum Chrome {
        static let homeHighlightStrokeOpacity: CGFloat = 0.5
        static let homeHighlightBlurRadius: CGFloat = 0.3
        static let homeHighlightStrokeWidth: CGFloat = 1
        static let homeBaseStrokeOpacity: CGFloat = 0.05
    }
}

extension View {
    func vibriseMavenText(
        size: CGFloat,
        color: Color = DesignTokens.Colors.primaryText
    ) -> some View {
        self
            .font(DesignTokens.Typography.mavenProFont(size: size))
            .tracking(DesignTokens.Typography.tracking(for: size))
            .foregroundStyle(color)
    }

    func vibriseSatoshiText(
        size: CGFloat,
        weight: Font.Weight = .regular,
        color: Color = DesignTokens.Colors.primaryText
    ) -> some View {
        self
            .font(DesignTokens.Typography.satoshiFont(size: size))
            .fontWeight(weight)
            .lineSpacing(DesignTokens.Typography.satoshiLineSpacing(for: size))
            .foregroundStyle(color)
    }
}
