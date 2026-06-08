import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RingAmbientBackgroundView: View {
    let style: HomeBackgroundStyle
    let seed: UInt64

    var body: some View {
        ZStack {
            LinearGradient(
                colors: style.baseGradient,
                startPoint: .top,
                endPoint: .bottom
            )

            ForEach(Array(style.accentLayers.enumerated()), id: \.offset) { _, layer in
                RadialGradient(
                    colors: [
                        layer.color.opacity(layer.opacity),
                        layer.color.opacity(layer.opacity * 0.45),
                        .clear
                    ],
                    center: layer.center,
                    startRadius: 0,
                    endRadius: layer.radius
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .saturation(style.saturation)
        .brightness((style.brightness - 1) * 0.12)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: style)
    }
}

#if canImport(UIKit)
func makeRingArtworkBackgroundStyle(from image: UIImage, fallback: HomeBackgroundStyle) -> HomeBackgroundStyle {
    let palette = ringArtworkPalette(from: image)

    return HomeBackgroundStyle(
        baseGradient: [
            palette.primary.darkened(by: 0.78),
            palette.secondary.darkened(by: 0.86),
            palette.primary.darkened(by: 0.93)
        ],
        accentLayers: [
            .init(color: palette.primary, center: .init(x: 0.24, y: 0.26), radius: 290, opacity: 0.30),
            .init(color: palette.secondary, center: .init(x: 0.76, y: 0.70), radius: 250, opacity: 0.24),
            .init(color: palette.highlight, center: .init(x: 0.52, y: 0.18), radius: 190, opacity: 0.12)
        ],
        orbColors: [
            palette.primary,
            palette.secondary,
            palette.secondary.mix(with: palette.highlight, amount: 0.35),
            palette.highlight
        ],
        brightness: fallback.brightness,
        saturation: max(fallback.saturation, 1.12)
    )
}

private struct RingArtworkPalette {
    let primary: Color
    let secondary: Color
    let highlight: Color
}

private func ringArtworkPalette(from image: UIImage) -> RingArtworkPalette {
    let size = CGSize(width: 8, height: 8)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    let sampledImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }

    guard let cgImage = sampledImage.cgImage,
          let data = cgImage.dataProvider?.data,
          let pointer = CFDataGetBytePtr(data) else {
        return .init(primary: .orange, secondary: .purple, highlight: .white)
    }

    var colors: [UIColor] = []
    let bytesPerPixel = 4

    for y in 0..<cgImage.height {
        for x in 0..<cgImage.width {
            let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
            let red = CGFloat(pointer[offset]) / 255
            let green = CGFloat(pointer[offset + 1]) / 255
            let blue = CGFloat(pointer[offset + 2]) / 255
            let alpha = CGFloat(pointer[offset + 3]) / 255

            guard alpha > 0.2 else { continue }

            colors.append(UIColor(red: red, green: green, blue: blue, alpha: alpha))
        }
    }

    guard !colors.isEmpty else {
        return .init(primary: .orange, secondary: .purple, highlight: .white)
    }

    let sortedByVibrance = colors.sorted { lhs, rhs in
        ringVibranceScore(lhs) > ringVibranceScore(rhs)
    }

    let primary = sortedByVibrance.first ?? .systemOrange
    let secondary = sortedByVibrance.first(where: {
        ringColorDistance($0, primary) > 0.22
    }) ?? sortedByVibrance.dropFirst().first ?? .systemPurple

    let highlight = colors.sorted {
        ringBrightnessScore($0) > ringBrightnessScore($1)
    }.first(where: {
        ringBrightnessScore($0) > 0.72
    }) ?? .white

    return RingArtworkPalette(
        primary: Color(primary),
        secondary: Color(secondary),
        highlight: Color(highlight)
    )
}

private func ringVibranceScore(_ color: UIColor) -> CGFloat {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
        return 0
    }
    return saturation * 0.7 + brightness * 0.3
}

private func ringBrightnessScore(_ color: UIColor) -> CGFloat {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return 0
    }
    return red * 0.299 + green * 0.587 + blue * 0.114
}

private func ringColorDistance(_ lhs: UIColor, _ rhs: UIColor) -> CGFloat {
    var lRed: CGFloat = 0
    var lGreen: CGFloat = 0
    var lBlue: CGFloat = 0
    var lAlpha: CGFloat = 0
    var rRed: CGFloat = 0
    var rGreen: CGFloat = 0
    var rBlue: CGFloat = 0
    var rAlpha: CGFloat = 0

    guard lhs.getRed(&lRed, green: &lGreen, blue: &lBlue, alpha: &lAlpha),
          rhs.getRed(&rRed, green: &rGreen, blue: &rBlue, alpha: &rAlpha) else {
        return 0
    }

    let dr = lRed - rRed
    let dg = lGreen - rGreen
    let db = lBlue - rBlue
    return sqrt((dr * dr + dg * dg + db * db) / 3)
}

private extension Color {
    func darkened(by amount: CGFloat) -> Color {
        let color = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        return Color(
            red: max(red - amount, 0),
            green: max(green - amount, 0),
            blue: max(blue - amount, 0),
            opacity: alpha
        )
    }
}
#endif
