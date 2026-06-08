import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
enum ShareCardRenderer {
    static func makeImage(song: Song, shareMonthText: String, shareDayText: String) async throws -> UIImage {
        let artworkImage = await loadArtwork(from: song.artworkURL)
        let palette = artworkImage.map(extractPalette) ?? .fallback
        let bloomLayout = makeBloomLayout(seed: [song.id, song.title, song.artist, shareMonthText, shareDayText].joined(separator: "|"))
        
        return try await MainActor.run {
            let view = ShareCardView(
                song: song,
                shareMonthText: shareMonthText,
                shareDayText: shareDayText,
                artworkImage: artworkImage,
                palette: palette,
                bloomLayout: bloomLayout
            )

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1

            guard let image = renderer.uiImage else {
                throw ShareCardRendererError.renderFailed
            }

            return image
        }
    }

    private static func loadArtwork(from url: URL?) async -> UIImage? {
        guard let url else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private static func extractPalette(from image: UIImage) -> ShareCardPalette {
        guard let cgImage = image.cgImage else {
            return .fallback
        }

        let size = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        }

        guard let sampledCgImage = resized.cgImage,
              let data = sampledCgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .fallback
        }

        let positions = [(1, 1), (3, 1), (6, 1), (1, 3), (4, 3), (6, 3), (1, 6), (3, 6), (6, 6), (4, 5)]
        let colors: [UIColor] = positions.compactMap { x, y in
            shareCardColorAtPixel(x: x, y: y, bytes: bytes, bytesPerRow: sampledCgImage.bytesPerRow)
        }.map(shareCardBoostColor)

        guard !colors.isEmpty else {
            return .fallback
        }

        var bestPair = (colors[0], colors.count > 1 ? colors[1] : colors[0])
        var maxDistance: CGFloat = -1

        for i in colors.indices {
            for j in colors.indices where j > i {
                let distance = shareCardColorDistance(colors[i], colors[j])
                if distance > maxDistance {
                    maxDistance = distance
                    bestPair = (colors[i], colors[j])
                }
            }
        }

        return ShareCardPalette(
            large: Color(uiColor: bestPair.0),
            small: Color(uiColor: bestPair.1)
        )
    }

    private static func makeBloomLayout(seed: String) -> ShareCardBloomLayout {
        ShareCardBloomLayout(
            largeX: 16 + 20 * shareCardSeededUnit(seed: seed, salt: 1),
            largeY: 18 + 20 * shareCardSeededUnit(seed: seed, salt: 2),
            largeRadius: 80 + 40 * shareCardSeededUnit(seed: seed, salt: 3),
            smallX: 62 + 18 * shareCardSeededUnit(seed: seed, salt: 4),
            smallY: 58 + 18 * shareCardSeededUnit(seed: seed, salt: 5),
            smallRadius: 60 + 30 * shareCardSeededUnit(seed: seed, salt: 6)
        )
    }
}

private func shareCardColorAtPixel(x: Int, y: Int, bytes: UnsafePointer<UInt8>, bytesPerRow: Int) -> UIColor? {
    let offset = y * bytesPerRow + x * 4
    let red = CGFloat(bytes[offset]) / 255
    let green = CGFloat(bytes[offset + 1]) / 255
    let blue = CGFloat(bytes[offset + 2]) / 255
    let alpha = CGFloat(bytes[offset + 3]) / 255

    guard alpha > 0 else {
        return nil
    }

    return UIColor(red: red * 1.06, green: green * 1.06, blue: blue * 1.06, alpha: 1)
}

private func shareCardBoostColor(_ color: UIColor) -> UIColor {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    let luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue)
    let maxComponent = max(red, green, blue)
    let minComponent = min(red, green, blue)
    let saturation = maxComponent == 0 ? 0 : (maxComponent - minComponent) / maxComponent
    let boost = 1.08 + saturation * 0.18 + (0.55 - min(luminance, 0.55)) * 0.28

    return UIColor(
        red: min(red * boost, 1),
        green: min(green * boost, 1),
        blue: min(blue * boost, 1),
        alpha: 1
    )
}

private func shareCardColorDistance(_ lhs: UIColor, _ rhs: UIColor) -> CGFloat {
    var lRed: CGFloat = 0
    var lGreen: CGFloat = 0
    var lBlue: CGFloat = 0
    var lAlpha: CGFloat = 0
    var rRed: CGFloat = 0
    var rGreen: CGFloat = 0
    var rBlue: CGFloat = 0
    var rAlpha: CGFloat = 0

    lhs.getRed(&lRed, green: &lGreen, blue: &lBlue, alpha: &lAlpha)
    rhs.getRed(&rRed, green: &rGreen, blue: &rBlue, alpha: &rAlpha)

    let dr = lRed - rRed
    let dg = lGreen - rGreen
    let db = lBlue - rBlue
    return sqrt(dr * dr + dg * dg + db * db)
}

private func shareCardSeededUnit(seed: String, salt: UInt64) -> CGFloat {
    var hash: UInt64 = 1469598103934665603 ^ salt
    for scalar in seed.unicodeScalars {
        hash ^= UInt64(scalar.value) &+ salt &* 31
        hash &*= 1099511628211
    }
    return CGFloat(hash % 10_000) / 10_000
}

enum ShareCardRendererError: Error {
    case renderFailed
}

struct ShareSheetPayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
#endif
