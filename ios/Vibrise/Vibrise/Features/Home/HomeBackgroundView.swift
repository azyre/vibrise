import SwiftUI

struct HomeBackgroundView: View {
    let style: HomeBackgroundStyle
    let seed: UInt64
    let artworkImageData: Data?

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

            #if canImport(UIKit)
            if let artworkImageData, let uiImage = UIImage(data: artworkImageData) {
                GeometryReader { geo in
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .blur(radius: 60)
                .overlay(Color.black.opacity(0.35))
                .transition(.opacity)
            }
            #endif

            HomeBackgroundOrbField(colors: style.orbColors, layoutSeed: seed)
                .opacity(0.82)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.04),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.18)
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
