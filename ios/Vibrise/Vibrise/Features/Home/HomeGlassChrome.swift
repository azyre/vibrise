import SwiftUI

private struct HomeGlassChromeConfig {
    let startAngle: Angle
    let endAngle: Angle
    let primaryLineWidth: CGFloat
    let primaryStops: [Gradient.Stop]
    let softLineWidth: CGFloat
    let softBlur: CGFloat
    let softStops: [Gradient.Stop]
}

private func homeGlassLerp(_ start: CGFloat, _ end: CGFloat, t: CGFloat) -> CGFloat {
    start + (end - start) * t
}

private func homeGlassChromeConfig(for size: CGSize) -> HomeGlassChromeConfig {
    let width = max(size.width, 1)
    let height = max(size.height, 1)
    let diagonalAxisAngle = Angle.radians(atan2(height, width))
    let diagonalAngleDegrees = max(diagonalAxisAngle.degrees, 1)
    // 45deg is square-like; smaller angles mean a flatter, wider component.
    let normalizedFlatness = min(max((45 - diagonalAngleDegrees) / 30, 0), 1)
    let primaryFadeNear = homeGlassLerp(0.12, 0.05, t: normalizedFlatness)
    let primaryFadeFar = homeGlassLerp(0.25, 0.13, t: normalizedFlatness)
    let softFadeNear = homeGlassLerp(0.12, 0.04, t: normalizedFlatness)
    let softFadeFar = homeGlassLerp(0.25, 0.12, t: normalizedFlatness)
    let primaryShoulderOpacity = homeGlassLerp(0.08, 0.05, t: normalizedFlatness)
    let primaryDarkOpacity = homeGlassLerp(0.06, 0.03, t: normalizedFlatness)
    let softShoulderOpacity = homeGlassLerp(0.04, 0.02, t: normalizedFlatness)
    let softDarkOpacity = homeGlassLerp(0.03, 0.01, t: normalizedFlatness)

    return HomeGlassChromeConfig(
        startAngle: diagonalAxisAngle,
        endAngle: diagonalAxisAngle + .degrees(360),
        primaryLineWidth: 1,
        primaryStops: [
            .init(color: Color.white.opacity(0.34), location: 0.0),
            .init(color: Color.white.opacity(primaryShoulderOpacity), location: primaryFadeNear),
            .init(color: Color.white.opacity(primaryDarkOpacity), location: primaryFadeFar),
            .init(color: Color.white.opacity(0.32), location: 0.5),
            .init(color: Color.white.opacity(primaryShoulderOpacity), location: 0.5 + primaryFadeNear),
            .init(color: Color.white.opacity(primaryDarkOpacity), location: 0.5 + primaryFadeFar),
            .init(color: Color.white.opacity(0.34), location: 1.0)
        ],
        softLineWidth: 3 + min(max((width / height - 1) / 3, 0), 1),
        softBlur: 1.2 + (min(max((width / height - 1) / 3, 0), 1) * 0.8),
        softStops: [
            .init(color: Color.white.opacity(0.08), location: 0.0),
            .init(color: Color.white.opacity(softShoulderOpacity), location: softFadeNear),
            .init(color: Color.white.opacity(softDarkOpacity), location: softFadeFar),
            .init(color: Color.white.opacity(0.07), location: 0.5),
            .init(color: Color.white.opacity(softShoulderOpacity), location: 0.5 + softFadeNear),
            .init(color: Color.white.opacity(softDarkOpacity), location: 0.5 + softFadeFar),
            .init(color: Color.white.opacity(0.08), location: 1.0)
        ]
    )
}

private struct HomeGlassChromeBackground<S: InsettableShape>: View {
    let shape: S
    let size: CGSize

    var body: some View {
        let config = homeGlassChromeConfig(for: size)

        ZStack {
            shape
                .fill(Color.white.opacity(0.10))
                .blur(radius: 18)

            shape
                .stroke(
                    AngularGradient(
                        stops: config.primaryStops,
                        center: .center,
                        startAngle: config.startAngle,
                        endAngle: config.endAngle
                    ),
                    lineWidth: config.primaryLineWidth
                )

            shape
                .stroke(
                    AngularGradient(
                        stops: config.softStops,
                        center: .center,
                        startAngle: config.startAngle,
                        endAngle: config.endAngle
                    ),
                    lineWidth: config.softLineWidth
                )
                .blur(radius: config.softBlur)
        }
    }
}

private struct HomeGlassChromeModifier<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    HomeGlassChromeBackground(
                        shape: shape,
                        size: geo.size
                    )
                }
            }
            .clipShape(shape)
    }
}

extension View {
    func homeGlassChrome<S: InsettableShape>(_ shape: S) -> some View {
        modifier(
            HomeGlassChromeModifier(
                shape: shape
            )
        )
    }
}
