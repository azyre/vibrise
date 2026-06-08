import SwiftUI

struct HomeBackgroundStyle: Equatable {
    let baseGradient: [Color]
    let accentLayers: [AccentLayer]
    let orbColors: [Color]
    let brightness: Double
    let saturation: Double

    struct AccentLayer: Equatable {
        let color: Color
        let center: UnitPoint
        let radius: CGFloat
        let opacity: Double
    }
}

extension HomeBackgroundStyle {
    static func make(weather: WeatherContext?, now: Date = Date()) -> HomeBackgroundStyle {
        let weatherCode = weather?.weatherCode ?? 2
        let temperature = weather?.temperatureCelsius ?? 20
        let daylight = daylightFactor(now: now)

        let palette = paletteForWeather(code: weatherCode, temperature: temperature)
        let brightness = 0.5 + 0.7 * daylight
        let saturation = 0.68 + 0.08 * daylight

        return HomeBackgroundStyle(
            baseGradient: palette.baseGradient,
            accentLayers: palette.accentLayers,
            orbColors: palette.orbColors,
            brightness: brightness,
            saturation: saturation
        )
    }

    private static func daylightFactor(now: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: now)
        let hour = Double(components.hour ?? 12)
        let minute = Double(components.minute ?? 0)
        let currentHour = hour + minute / 60
        return 0.5 + 0.5 * cos((currentHour - 12) * .pi / 12)
    }

    private static func paletteForWeather(code: Int, temperature: Double) -> HomeBackgroundPalette {
        if code >= 95 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.03, green: 0.02, blue: 0.10),
                    Color(red: 0.08, green: 0.04, blue: 0.16),
                    Color(red: 0.04, green: 0.02, blue: 0.08)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.47, green: 0.20, blue: 0.71), center: .init(x: 0.22, y: 0.28), radius: 300, opacity: 0.50),
                    .init(color: Color(red: 0.20, green: 0.12, blue: 0.55), center: .init(x: 0.80, y: 0.72), radius: 260, opacity: 0.40),
                    .init(color: Color(red: 0.78, green: 0.71, blue: 1.0), center: .init(x: 0.60, y: 0.15), radius: 180, opacity: 0.12)
                ],
                orbColors: [
                    Color(red: 0.47, green: 0.20, blue: 0.71),
                    Color(red: 0.20, green: 0.12, blue: 0.55),
                    Color(red: 0.59, green: 0.29, blue: 0.76),
                    Color(red: 0.78, green: 0.71, blue: 1.0)
                ]
            )
        }

        if (71...77).contains(code) {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.05, green: 0.06, blue: 0.09),
                    Color(red: 0.08, green: 0.09, blue: 0.13),
                    Color(red: 0.05, green: 0.05, blue: 0.09)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.71, green: 0.76, blue: 0.86), center: .init(x: 0.30, y: 0.22), radius: 280, opacity: 0.40),
                    .init(color: Color(red: 0.59, green: 0.65, blue: 0.78), center: .init(x: 0.72, y: 0.76), radius: 250, opacity: 0.30),
                    .init(color: Color(red: 0.78, green: 0.82, blue: 0.90), center: .init(x: 0.52, y: 0.50), radius: 220, opacity: 0.14)
                ],
                orbColors: [
                    Color(red: 0.71, green: 0.76, blue: 0.86),
                    Color(red: 0.59, green: 0.65, blue: 0.78),
                    Color(red: 0.67, green: 0.71, blue: 0.82),
                    Color(red: 0.78, green: 0.82, blue: 0.90)
                ]
            )
        }

        if code >= 61 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color(red: 0.04, green: 0.06, blue: 0.16),
                    Color(red: 0.02, green: 0.04, blue: 0.09)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.20, green: 0.31, blue: 0.63), center: .init(x: 0.25, y: 0.34), radius: 280, opacity: 0.45),
                    .init(color: Color(red: 0.16, green: 0.24, blue: 0.51), center: .init(x: 0.76, y: 0.68), radius: 250, opacity: 0.35),
                    .init(color: Color(red: 0.27, green: 0.39, blue: 0.71), center: .init(x: 0.42, y: 0.80), radius: 200, opacity: 0.18)
                ],
                orbColors: [
                    Color(red: 0.20, green: 0.31, blue: 0.63),
                    Color(red: 0.16, green: 0.24, blue: 0.51),
                    Color(red: 0.27, green: 0.39, blue: 0.71),
                    Color(red: 0.24, green: 0.35, blue: 0.59)
                ]
            )
        }

        if code >= 51 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    Color(red: 0.06, green: 0.08, blue: 0.13),
                    Color(red: 0.04, green: 0.05, blue: 0.09)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.39, green: 0.51, blue: 0.78), center: .init(x: 0.30, y: 0.25), radius: 280, opacity: 0.35),
                    .init(color: Color(red: 0.31, green: 0.43, blue: 0.67), center: .init(x: 0.66, y: 0.72), radius: 250, opacity: 0.25),
                    .init(color: Color(red: 0.51, green: 0.59, blue: 0.78), center: .init(x: 0.50, y: 0.45), radius: 200, opacity: 0.15)
                ],
                orbColors: [
                    Color(red: 0.39, green: 0.51, blue: 0.78),
                    Color(red: 0.31, green: 0.43, blue: 0.67),
                    Color(red: 0.35, green: 0.47, blue: 0.73),
                    Color(red: 0.47, green: 0.57, blue: 0.82)
                ]
            )
        }

        if (45...48).contains(code) {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.05, green: 0.05, blue: 0.07),
                    Color(red: 0.06, green: 0.07, blue: 0.09),
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.47, green: 0.51, blue: 0.57), center: .init(x: 0.35, y: 0.30), radius: 250, opacity: 0.35),
                    .init(color: Color(red: 0.39, green: 0.45, blue: 0.51), center: .init(x: 0.65, y: 0.65), radius: 240, opacity: 0.25),
                    .init(color: Color(red: 0.55, green: 0.57, blue: 0.61), center: .init(x: 0.50, y: 0.50), radius: 220, opacity: 0.12)
                ],
                orbColors: [
                    Color(red: 0.47, green: 0.51, blue: 0.57),
                    Color(red: 0.39, green: 0.45, blue: 0.51),
                    Color(red: 0.43, green: 0.48, blue: 0.54),
                    Color(red: 0.55, green: 0.57, blue: 0.61)
                ]
            )
        }

        if (2...3).contains(code) {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.11),
                    Color(red: 0.04, green: 0.05, blue: 0.07)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.55, green: 0.59, blue: 0.69), center: .init(x: 0.30, y: 0.25), radius: 260, opacity: 0.30),
                    .init(color: Color(red: 0.45, green: 0.49, blue: 0.59), center: .init(x: 0.72, y: 0.72), radius: 250, opacity: 0.25),
                    .init(color: Color(red: 0.63, green: 0.65, blue: 0.71), center: .init(x: 0.50, y: 0.45), radius: 210, opacity: 0.10)
                ],
                orbColors: [
                    Color(red: 0.55, green: 0.59, blue: 0.69),
                    Color(red: 0.45, green: 0.49, blue: 0.59),
                    Color(red: 0.51, green: 0.55, blue: 0.65),
                    Color(red: 0.63, green: 0.65, blue: 0.71)
                ]
            )
        }

        if temperature >= 30 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.10, green: 0.07, blue: 0.03),
                    Color(red: 0.12, green: 0.08, blue: 0.05),
                    Color(red: 0.08, green: 0.05, blue: 0.03)
                ],
                accentLayers: [
                    .init(color: Color(red: 1.0, green: 0.55, blue: 0.16), center: .init(x: 0.30, y: 0.25), radius: 280, opacity: 0.45),
                    .init(color: Color(red: 0.86, green: 0.31, blue: 0.12), center: .init(x: 0.72, y: 0.72), radius: 240, opacity: 0.30),
                    .init(color: Color(red: 1.0, green: 0.71, blue: 0.31), center: .init(x: 0.50, y: 0.10), radius: 180, opacity: 0.20)
                ],
                orbColors: [
                    Color(red: 1.0, green: 0.55, blue: 0.16),
                    Color(red: 0.86, green: 0.31, blue: 0.12),
                    Color(red: 0.94, green: 0.43, blue: 0.14),
                    Color(red: 1.0, green: 0.71, blue: 0.31)
                ]
            )
        }

        if temperature >= 20 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.08, green: 0.06, blue: 0.03),
                    Color(red: 0.10, green: 0.09, blue: 0.05),
                    Color(red: 0.07, green: 0.05, blue: 0.03)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.94, green: 0.71, blue: 0.31), center: .init(x: 0.25, y: 0.30), radius: 280, opacity: 0.40),
                    .init(color: Color(red: 0.78, green: 0.59, blue: 0.24), center: .init(x: 0.75, y: 0.65), radius: 240, opacity: 0.30),
                    .init(color: Color(red: 1.0, green: 0.78, blue: 0.39), center: .init(x: 0.55, y: 0.20), radius: 190, opacity: 0.15)
                ],
                orbColors: [
                    Color(red: 0.94, green: 0.71, blue: 0.31),
                    Color(red: 0.78, green: 0.59, blue: 0.24),
                    Color(red: 0.86, green: 0.65, blue: 0.27),
                    Color(red: 1.0, green: 0.78, blue: 0.39)
                ]
            )
        }

        if temperature >= 10 {
            return HomeBackgroundPalette(
                baseGradient: [
                    Color(red: 0.04, green: 0.06, blue: 0.08),
                    Color(red: 0.05, green: 0.09, blue: 0.10),
                    Color(red: 0.03, green: 0.05, blue: 0.07)
                ],
                accentLayers: [
                    .init(color: Color(red: 0.39, green: 0.71, blue: 0.78), center: .init(x: 0.30, y: 0.25), radius: 260, opacity: 0.35),
                    .init(color: Color(red: 0.31, green: 0.59, blue: 0.71), center: .init(x: 0.70, y: 0.70), radius: 230, opacity: 0.25),
                    .init(color: Color(red: 0.47, green: 0.78, blue: 0.86), center: .init(x: 0.45, y: 0.15), radius: 180, opacity: 0.15)
                ],
                orbColors: [
                    Color(red: 0.39, green: 0.71, blue: 0.78),
                    Color(red: 0.31, green: 0.59, blue: 0.71),
                    Color(red: 0.35, green: 0.65, blue: 0.75),
                    Color(red: 0.47, green: 0.78, blue: 0.86)
                ]
            )
        }

        return HomeBackgroundPalette(
            baseGradient: [
                Color(red: 0.03, green: 0.05, blue: 0.09),
                Color(red: 0.05, green: 0.08, blue: 0.13),
                Color(red: 0.03, green: 0.04, blue: 0.08)
            ],
            accentLayers: [
                .init(color: Color(red: 0.31, green: 0.47, blue: 0.75), center: .init(x: 0.25, y: 0.30), radius: 250, opacity: 0.35),
                .init(color: Color(red: 0.24, green: 0.39, blue: 0.67), center: .init(x: 0.70, y: 0.65), radius: 220, opacity: 0.25),
                .init(color: Color(red: 0.39, green: 0.55, blue: 0.78), center: .init(x: 0.50, y: 0.20), radius: 180, opacity: 0.15)
            ],
            orbColors: [
                Color(red: 0.31, green: 0.47, blue: 0.75),
                Color(red: 0.24, green: 0.39, blue: 0.67),
                Color(red: 0.27, green: 0.43, blue: 0.71),
                Color(red: 0.39, green: 0.55, blue: 0.78)
            ]
        )
    }
}

private struct HomeBackgroundPalette {
    let baseGradient: [Color]
    let accentLayers: [HomeBackgroundStyle.AccentLayer]
    let orbColors: [Color]
}
