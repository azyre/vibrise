import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
struct ShareCardView: View {
    let song: Song
    let shareMonthText: String
    let shareDayText: String
    let artworkImage: UIImage?
    let palette: ShareCardPalette
    let bloomLayout: ShareCardBloomLayout

    init(
        song: Song,
        shareMonthText: String,
        shareDayText: String,
        artworkImage: UIImage?,
        palette: ShareCardPalette = .fallback,
        bloomLayout: ShareCardBloomLayout = .fallback
    ) {
        self.song = song
        self.shareMonthText = shareMonthText
        self.shareDayText = shareDayText
        self.artworkImage = artworkImage
        self.palette = palette
        self.bloomLayout = bloomLayout
    }

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1352

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer
            artworkBlock
                .frame(width: 550, height: 550)
                .offset(x: 110, y: 110)

            titleBlock
                .offset(x: 110, y: 693)

            artistBlock
                .offset(x: 110, y: 759)

            monthBlock
                .offset(x: 110, y: 1165)

            dayBlock
                .offset(x: 110, y: 1209)

            brandBlock
                .offset(x: 451, y: 1154)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipped()
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 18 / 255, green: 27 / 255, blue: 40 / 255),
                    Color(red: 16 / 255, green: 24 / 255, blue: 35 / 255),
                    Color(red: 13 / 255, green: 20 / 255, blue: 29 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth * 1.2, height: cardHeight * 1.2)
                    .blur(radius: 160)
                    .brightness(-0.4)
                    .offset(x: -24, y: -41)
            }

            bloom(
                color: palette.large,
                radiusPercent: bloomLayout.largeRadius,
                centerXPercent: bloomLayout.largeX,
                centerYPercent: bloomLayout.largeY,
                innerOpacity: 0.10,
                outerOpacity: 0.055
            )

            bloom(
                color: palette.small,
                radiusPercent: bloomLayout.smallRadius,
                centerXPercent: bloomLayout.smallX,
                centerYPercent: bloomLayout.smallY,
                innerOpacity: 0.05,
                outerOpacity: 0.028
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.white.opacity(0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 520
            )
            .frame(width: 1040, height: 1040)
                .position(x: 540, y: 432)

            RadialGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 540
            )
            .frame(width: 1080, height: 1080)
                .position(x: 540, y: 973)

            LinearGradient(
                colors: [
                    Color(red: 8 / 255, green: 12 / 255, blue: 18 / 255).opacity(0.06),
                    Color(red: 8 / 255, green: 12 / 255, blue: 18 / 255).opacity(0.20),
                    Color(red: 8 / 255, green: 12 / 255, blue: 18 / 255).opacity(0.46)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var artworkBlock: some View {
        Group {
            if let artworkImage {
                Image(uiImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 120, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.88))
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
    }

    private var titleBlock: some View {
        Text(song.title)
            .font(preferredFont("Satoshi-Regular", fallbackName: "Satoshi", size: 44))
            .foregroundStyle(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: 760, alignment: .leading)
            .lineSpacing(0)
    }

    private var artistBlock: some View {
        Text(song.artist)
            .font(preferredFont("Satoshi-Regular", fallbackName: "Satoshi", size: 44))
            .foregroundStyle(Color.white.opacity(0.2))
            .blendMode(.plusLighter)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: 760, alignment: .leading)
            .lineSpacing(0)
    }

    private var monthBlock: some View {
        Text(shareMonthText)
            .font(preferredFont("Satoshi-Regular", fallbackName: "Satoshi", size: 44))
            .foregroundStyle(.white)
            .frame(width: 220, alignment: .leading)
    }

    private var dayBlock: some View {
        Text(shareDayText)
            .font(preferredFont("Satoshi-Regular", fallbackName: "Satoshi", size: 44))
            .foregroundStyle(.white)
            .frame(width: 220, alignment: .leading)
    }

    private var brandBlock: some View {
        Text("Vibrise")
            .font(preferredFont("MavenPro-Regular", fallbackName: "Maven Pro", size: 99, fallbackWeight: .regular, fallbackDesign: .rounded))
            .tracking(-3.96)
            .foregroundStyle(.white)
            .frame(width: 519, alignment: .trailing)
    }

    private func bloom(
        color: Color,
        radiusPercent: CGFloat,
        centerXPercent: CGFloat,
        centerYPercent: CGFloat,
        innerOpacity: CGFloat,
        outerOpacity: CGFloat
    ) -> some View {
        RadialGradient(
            stops: [
                .init(color: color.opacity(innerOpacity), location: 0),
                .init(color: color.opacity(outerOpacity), location: 0.24),
                .init(color: color.opacity(max(outerOpacity * 0.5, 0.04)), location: 0.44),
                .init(color: color.opacity(max(outerOpacity * 0.18, 0.018)), location: 0.60),
                .init(color: color.opacity(max(outerOpacity * 0.08, 0.008)), location: 0.74),
                .init(color: color.opacity(0), location: 1)
            ],
            center: .center,
            startRadius: 0,
            endRadius: cardWidth * (radiusPercent / 100)
        )
            .frame(
                width: cardWidth * (radiusPercent / 100) * 2,
                height: cardWidth * (radiusPercent / 100) * 2
            )
            .blendMode(.screen)
            .position(
                x: cardWidth * (centerXPercent / 100),
                y: cardHeight * (centerYPercent / 100)
            )
    }

    private func preferredFont(
        _ name: String,
        fallbackName: String,
        size: CGFloat,
        fallbackWeight: Font.Weight = .regular,
        fallbackDesign: Font.Design = .default
    ) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        if UIFont(name: fallbackName, size: size) != nil {
            return .custom(fallbackName, size: size)
        }
        return .system(size: size, weight: fallbackWeight, design: fallbackDesign)
    }
}

struct ShareCardPalette {
    let large: Color
    let small: Color

    static let fallback = ShareCardPalette(
        large: Color(red: 116 / 255, green: 160 / 255, blue: 224 / 255),
        small: Color(red: 88 / 255, green: 198 / 255, blue: 168 / 255)
    )
}

struct ShareCardBloomLayout {
    let largeX: CGFloat
    let largeY: CGFloat
    let largeRadius: CGFloat
    let smallX: CGFloat
    let smallY: CGFloat
    let smallRadius: CGFloat

    static let fallback = ShareCardBloomLayout(
        largeX: 22,
        largeY: 24,
        largeRadius: 92,
        smallX: 76,
        smallY: 70,
        smallRadius: 74
    )
}

#Preview {
    ShareCardView(
        song: .mockMorningLight,
        shareMonthText: "Mar",
        shareDayText: "23",
        artworkImage: nil
    )
    .frame(width: 320, height: 401)
}
#endif
