import SwiftUI

struct HomeBackgroundOrbField: View {
    let colors: [Color]
    let layoutSeed: UInt64

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let primaryCenter = homeOrbCenter(seed: layoutSeed, index: 0, size: proxy.size)
                let secondaryCenter = homeOrbCenter(seed: layoutSeed, index: 1, size: proxy.size)
                let highlightCenter = homeOrbCenter(seed: layoutSeed, index: 2, size: proxy.size)
                let primarySize = homeOrbSize(seed: layoutSeed, index: 0, base: CGSize(width: 430, height: 430))
                let secondarySize = homeOrbSize(seed: layoutSeed, index: 1, base: CGSize(width: 560, height: 560))
                let highlightSize = homeOrbSize(seed: layoutSeed, index: 2, base: CGSize(width: 500, height: 500))
                let primaryAmplitude = homeOrbAmplitude(seed: layoutSeed, index: 0, base: CGSize(width: 72, height: 46))
                let secondaryAmplitude = homeOrbAmplitude(seed: layoutSeed, index: 1, base: CGSize(width: 86, height: 62))
                let highlightAmplitude = homeOrbAmplitude(seed: layoutSeed, index: 2, base: CGSize(width: 64, height: 44))
                let primarySpeed = homeOrbSpeed(seed: layoutSeed, index: 0, base: 0.12)
                let secondarySpeed = homeOrbSpeed(seed: layoutSeed, index: 1, base: 0.075)
                let highlightSpeed = homeOrbSpeed(seed: layoutSeed, index: 2, base: 0.16)
                let primaryRotation = homeOrbRotation(seed: layoutSeed, index: 0)
                let secondaryRotation = homeOrbRotation(seed: layoutSeed, index: 1)
                let highlightRotation = homeOrbRotation(seed: layoutSeed, index: 2)
                let primaryMotion = homeOrbMotion(seed: layoutSeed, index: 0)
                let secondaryMotion = homeOrbMotion(seed: layoutSeed, index: 1)
                let highlightMotion = homeOrbMotion(seed: layoutSeed, index: 2)
                let primaryAccent = homeOrbAccent(seed: layoutSeed, index: 0, size: primarySize)
                let secondaryAccent = homeOrbAccent(seed: layoutSeed, index: 1, size: secondarySize)
                let highlightAccent = homeOrbAccent(seed: layoutSeed, index: 2, size: highlightSize)
                let primaryOpacity = homeOrbOpacity(seed: layoutSeed, index: 0, baseInner: 0.18, baseOuter: 0.05)
                let secondaryOpacity = homeOrbOpacity(seed: layoutSeed, index: 1, baseInner: 0.18, baseOuter: 0.05)
                let highlightOpacity = homeOrbOpacity(seed: layoutSeed, index: 2, baseInner: 0.18, baseOuter: 0.05)

                ZStack {
                    HomeBackgroundOrb(
                        colorA: homeOrbPrimaryColor(from: colors),
                        colorB: homeOrbSecondaryGlow(from: colors),
                        size: primarySize,
                        center: primaryCenter,
                        amplitude: primaryAmplitude,
                        speed: primarySpeed,
                        rotationDegrees: primaryRotation,
                        motion: primaryMotion,
                        accent: primaryAccent,
                        innerOpacity: primaryOpacity.inner,
                        outerOpacity: primaryOpacity.outer,
                        time: time
                    )

                    HomeBackgroundOrb(
                        colorA: homeOrbSecondaryColor(from: colors),
                        colorB: homeOrbPrimaryColor(from: colors),
                        size: secondarySize,
                        center: secondaryCenter,
                        amplitude: secondaryAmplitude,
                        speed: secondarySpeed,
                        rotationDegrees: secondaryRotation,
                        motion: secondaryMotion,
                        accent: secondaryAccent,
                        innerOpacity: secondaryOpacity.inner,
                        outerOpacity: secondaryOpacity.outer,
                        time: time + 1.2
                    )

                    HomeBackgroundOrb(
                        colorA: homeOrbHighlightColor(from: colors),
                        colorB: homeOrbSecondaryColor(from: colors),
                        size: highlightSize,
                        center: highlightCenter,
                        amplitude: highlightAmplitude,
                        speed: highlightSpeed,
                        rotationDegrees: highlightRotation,
                        motion: highlightMotion,
                        accent: highlightAccent,
                        innerOpacity: highlightOpacity.inner,
                        outerOpacity: highlightOpacity.outer,
                        time: time + 2.1
                    )
                }
            }
        }
        .blur(radius: 42)
        .allowsHitTesting(false)
    }
}

struct HomeBackgroundOrb: View {
    let colorA: Color
    let colorB: Color
    let size: CGSize
    let center: CGPoint
    let amplitude: CGSize
    let speed: Double
    let rotationDegrees: Double
    let motion: HomeOrbMotion
    let accent: HomeOrbAccent
    let innerOpacity: Double
    let outerOpacity: Double
    let time: TimeInterval

    var body: some View {
        let phase = time * speed
        let x = center.x + sin(phase * motion.xFrequency + motion.xPhase) * amplitude.width * motion.xDirection
        let y = center.y + cos(phase * motion.yFrequency + motion.yPhase) * amplitude.height * motion.yDirection

        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: colorA.opacity(innerOpacity), location: 0),
                            .init(color: colorA.opacity(innerOpacity * 0.72), location: 0.24),
                            .init(color: colorB.opacity(max(outerOpacity * 1.8, 0.26)), location: 0.60),
                            .init(color: .clear, location: 1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(size.width, size.height) * 0.5
                    )
                )

            Ellipse()
                .fill(colorB.opacity(max(outerOpacity * 2.1, 0.34)))
                .frame(width: accent.size.width, height: accent.size.height)
                .rotationEffect(.degrees(accent.rotationDegrees))
                .offset(x: accent.offset.width, y: accent.offset.height)
                .blur(radius: 6)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(1.08)
        .rotationEffect(.degrees(rotationDegrees))
        .blendMode(.screen)
        .position(x: x, y: y)
    }
}

struct HomeOrbMotion {
    let xDirection: CGFloat
    let yDirection: CGFloat
    let xFrequency: Double
    let yFrequency: Double
    let xPhase: Double
    let yPhase: Double
}

struct HomeOrbAccent {
    let size: CGSize
    let offset: CGSize
    let rotationDegrees: Double
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

func homeOrbPrimaryColor(from colors: [Color]) -> Color {
    colors[safe: 0] ?? Color.orange
}

func homeOrbSecondaryColor(from colors: [Color]) -> Color {
    let base = colors[safe: 1] ?? colors[safe: 2] ?? Color.purple
    let mixed = base
        .mix(with: colors[safe: 2] ?? Color.cyan, amount: 0.96)
        .mix(with: colors[safe: 3] ?? Color.white, amount: 0.40)
    return mixed
        .shiftedHue(by: 0.16)
        .saturated(by: 0.72)
        .brightened(by: 0.22)
}

func homeOrbSecondaryGlow(from colors: [Color]) -> Color {
    let base = colors[safe: 2] ?? colors[safe: 1] ?? Color.pink
    return base
        .mix(with: colors[safe: 1] ?? Color.purple, amount: 0.62)
        .mix(with: colors[safe: 3] ?? Color.white, amount: 0.22)
        .shiftedHue(by: 0.12)
        .saturated(by: 0.70)
        .brightened(by: 0.18)
}

func homeOrbHighlightColor(from colors: [Color]) -> Color {
    let base = colors[safe: 3] ?? colors[safe: 2] ?? Color.white
    let shifted = base
        .mix(with: colors[safe: 2] ?? Color.cyan, amount: 0.84)
        .mix(with: colors[safe: 1] ?? Color.purple, amount: 0.38)
        .shiftedForHighlight()
        .shiftedHue(by: -0.18)
    return shifted.saturated(by: 0.72).brightened(by: 0.32)
}

func homeOrbCenter(seed: UInt64, index: Int, size: CGSize) -> CGPoint {
    let xRange: ClosedRange<CGFloat>
    let yRange: ClosedRange<CGFloat>

    switch index {
    case 0:
        xRange = 0.14 ... 0.34
        yRange = 0.14 ... 0.34
    case 1:
        xRange = 0.62 ... 0.84
        yRange = 0.50 ... 0.74
    default:
        xRange = 0.34 ... 0.60
        yRange = 0.68 ... 0.88
    }

    let x = homeOrbSeededValue(seed: seed, salt: UInt64(index * 2 + 1), range: xRange)
    let y = homeOrbSeededValue(seed: seed, salt: UInt64(index * 2 + 2), range: yRange)
    return CGPoint(x: size.width * x, y: size.height * y)
}

func homeOrbSize(seed: UInt64, index: Int, base: CGSize) -> CGSize {
    let widthScale = homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 21),
        range: 0.86 ... 1.26
    )
    let heightScale = homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 22),
        range: 0.72 ... 1.12
    )
    return CGSize(width: base.width * widthScale, height: base.height * heightScale)
}

func homeOrbAmplitude(seed: UInt64, index: Int, base: CGSize) -> CGSize {
    let widthScale = homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 31),
        range: 0.82 ... 1.22
    )
    let heightScale = homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 32),
        range: 0.82 ... 1.22
    )
    return CGSize(width: base.width * widthScale, height: base.height * heightScale)
}

func homeOrbSpeed(seed: UInt64, index: Int, base: Double) -> Double {
    Double(homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 41),
        range: 0.84 ... 1.22
    )) * base
}

func homeOrbRotation(seed: UInt64, index: Int) -> Double {
    Double(homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 45),
        range: -28 ... 28
    ))
}

func homeOrbMotion(seed: UInt64, index: Int) -> HomeOrbMotion {
    HomeOrbMotion(
        xDirection: homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 61), range: 0 ... 1) > 0.5 ? 1 : -1,
        yDirection: homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 62), range: 0 ... 1) > 0.5 ? 1 : -1,
        xFrequency: Double(homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 63), range: 0.78 ... 1.32)),
        yFrequency: Double(homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 64), range: 0.86 ... 1.44)),
        xPhase: Double(homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 65), range: 0 ... .pi * 2)),
        yPhase: Double(homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 66), range: 0 ... .pi * 2))
    )
}

func homeOrbAccent(seed: UInt64, index: Int, size: CGSize) -> HomeOrbAccent {
    let width = size.width * homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 71), range: 0.34 ... 0.52)
    let height = size.height * homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 72), range: 0.26 ... 0.44)
    let offsetX = size.width * homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 73), range: -0.24 ... 0.24)
    let offsetY = size.height * homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 74), range: -0.20 ... 0.20)
    let rotation = Double(homeOrbSeededValue(seed: seed, salt: UInt64(index * 10 + 75), range: -36 ... 36))

    return HomeOrbAccent(
        size: CGSize(width: width, height: height),
        offset: CGSize(width: offsetX, height: offsetY),
        rotationDegrees: rotation
    )
}

func homeOrbOpacity(seed: UInt64, index: Int, baseInner: Double, baseOuter: Double) -> (inner: Double, outer: Double) {
    let innerScale = Double(homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 51),
        range: 0.88 ... 1.18
    ))
    let outerScale = Double(homeOrbSeededValue(
        seed: seed,
        salt: UInt64(index * 2 + 52),
        range: 0.82 ... 1.22
    ))
    return (
        inner: min(baseInner * innerScale, 0.7),
        outer: min(baseOuter * outerScale, 0.32)
    )
}

func homeOrbSeededValue(seed: UInt64, salt: UInt64, range: ClosedRange<CGFloat>) -> CGFloat {
    let unit = homeOrbSeededUnit(seed: seed, salt: salt)
    return range.lowerBound + (range.upperBound - range.lowerBound) * unit
}

func homeOrbSeededUnit(seed: UInt64, salt: UInt64) -> CGFloat {
    var hash = seed ^ (salt &* 0x9E3779B185EBCA87)
    hash ^= hash >> 33
    hash &*= 0xff51afd7ed558ccd
    hash ^= hash >> 33
    hash &*= 0xc4ceb9fe1a85ec53
    hash ^= hash >> 33
    return CGFloat(hash % 10_000) / 10_000
}

extension Color {
    func mix(with other: Color, amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let lhs = UIColor(self)
        let rhs = UIColor(other)
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
            return self
        }

        let t = max(0, min(amount, 1))
        return Color(
            red: lRed + (rRed - lRed) * t,
            green: lGreen + (rGreen - lGreen) * t,
            blue: lBlue + (rBlue - lBlue) * t,
            opacity: lAlpha + (rAlpha - lAlpha) * t
        )
        #else
        return self
        #endif
    }

    func brightened(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let color = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        return Color(
            red: min(red + amount, 1),
            green: min(green + amount, 1),
            blue: min(blue + amount, 1),
            opacity: alpha
        )
        #else
        return self
        #endif
    }

    func saturated(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let color = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        return Color(
            hue: Double(hue),
            saturation: Double(min(saturation * amount, 1)),
            brightness: Double(brightness),
            opacity: Double(alpha)
        )
        #else
        return self
        #endif
    }

    func shiftedForHighlight() -> Color {
        #if canImport(UIKit)
        let color = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        let isWarm = hue < 0.16 || hue > 0.92
        let shiftedHue = isWarm
            ? (hue + 0.018).truncatingRemainder(dividingBy: 1)
            : (hue - 0.022 + 1).truncatingRemainder(dividingBy: 1)

        return Color(
            hue: Double(shiftedHue),
            saturation: Double(min(max(saturation * 1.04, 0.08), 1)),
            brightness: Double(brightness),
            opacity: Double(alpha)
        )
        #else
        return self
        #endif
    }

    func shiftedHue(by amount: CGFloat) -> Color {
        #if canImport(UIKit)
        let color = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        let shiftedHue = (hue + amount).truncatingRemainder(dividingBy: 1)
        let normalizedHue = shiftedHue < 0 ? shiftedHue + 1 : shiftedHue

        return Color(
            hue: Double(normalizedHue),
            saturation: Double(saturation),
            brightness: Double(brightness),
            opacity: Double(alpha)
        )
        #else
        return self
        #endif
    }
}
