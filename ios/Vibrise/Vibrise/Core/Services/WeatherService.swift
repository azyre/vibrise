import Foundation
import Combine
import CoreLocation

protocol WeatherService {
    func fetchCurrentWeather(for coordinates: WeatherCoordinates) async throws -> WeatherContext
}

struct WeatherContext: Equatable {
    let weatherCode: Int
    let temperatureCelsius: Double
}

struct WeatherInfo: Equatable {
    let name: String
    let tag: String
}

enum WeatherCatalog {
    static let defaultWeatherTag = "lounge+downtempo"

    static func info(for code: Int) -> WeatherInfo {
        weatherInfoByCode[code] ?? WeatherInfo(name: "Partly Cloudy", tag: defaultWeatherTag)
    }

    private static let weatherInfoByCode: [Int: WeatherInfo] = [
        0: WeatherInfo(name: "Clear", tag: "happy"),
        1: WeatherInfo(name: "Mostly Clear", tag: "happy"),
        2: WeatherInfo(name: "Partly Cloudy", tag: "lounge+downtempo"),
        3: WeatherInfo(name: "Overcast", tag: "chillout"),
        45: WeatherInfo(name: "Foggy", tag: "atmospheric"),
        51: WeatherInfo(name: "Light Rain", tag: "lofi+chillhop"),
        61: WeatherInfo(name: "Rain", tag: "jazz"),
        65: WeatherInfo(name: "Heavy Rain", tag: "cinematic"),
        71: WeatherInfo(name: "Light Snow", tag: "soft"),
        73: WeatherInfo(name: "Snow", tag: "newage"),
        95: WeatherInfo(name: "Thunderstorm", tag: "epic+adventure")
    ]
}

struct WeatherCoordinates: Equatable {
    let latitude: Double
    let longitude: Double

    static let prototypeFallback = WeatherCoordinates(latitude: 39.9, longitude: 116.4)
}

struct OpenMeteoWeatherService: WeatherService {
    let session: URLSession

    init(
        session: URLSession = .shared
    ) {
        self.session = session
    }

    func fetchCurrentWeather(for coordinates: WeatherCoordinates) async throws -> WeatherContext {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
            URLQueryItem(name: "current_weather", value: "true")
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoWeatherResponse.self, from: data)
        return WeatherContext(
            weatherCode: response.currentWeather.weatherCode,
            temperatureCelsius: response.currentWeather.temperature
        )
    }
}

enum WeatherServiceError: Error {
    case invalidURL
}

@MainActor
final class CachedWeatherSnapshotStore: ObservableObject, WeatherSnapshotProviding {
    @Published private(set) var currentWeather: WeatherContext?
    @Published private(set) var lastUpdatedAt: Date?

    private let service: WeatherService
    private let locationStore: CachedLocationSnapshotStore
    private let userDefaults: UserDefaults

    init() {
        self.service = OpenMeteoWeatherService()
        self.locationStore = CachedLocationSnapshotStore()
        self.userDefaults = .standard
        self.currentWeather = Self.readCachedWeather(from: .standard) ?? Self.fallbackWeather
        self.lastUpdatedAt = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date
    }

    init(
        service: WeatherService,
        locationStore: CachedLocationSnapshotStore,
        userDefaults: UserDefaults
    ) {
        self.service = service
        self.locationStore = locationStore
        self.userDefaults = userDefaults
        self.currentWeather = Self.readCachedWeather(from: userDefaults) ?? Self.fallbackWeather
        self.lastUpdatedAt = userDefaults.object(forKey: Self.cacheTimestampKey) as? Date
    }

    func refreshIfNeeded(maxAge: TimeInterval = 10 * 60) async {
        if let lastUpdatedAt, Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }

        await refresh()
    }

    func refresh() async {
        do {
            await locationStore.refreshIfNeeded()
            let coordinates = locationStore.currentCoordinates ?? .prototypeFallback
            let weather = try await service.fetchCurrentWeather(for: coordinates)
            apply(weather, at: Date())
        } catch {
            if currentWeather == nil {
                apply(Self.fallbackWeather, at: Date())
            }
        }
    }

    private func apply(_ weather: WeatherContext, at timestamp: Date) {
        currentWeather = weather
        lastUpdatedAt = timestamp
        userDefaults.set(weather.weatherCode, forKey: Self.cacheWeatherCodeKey)
        userDefaults.set(weather.temperatureCelsius, forKey: Self.cacheTemperatureKey)
        userDefaults.set(timestamp, forKey: Self.cacheTimestampKey)
    }

    private static func readCachedWeather(from userDefaults: UserDefaults) -> WeatherContext? {
        guard userDefaults.object(forKey: cacheWeatherCodeKey) != nil,
              userDefaults.object(forKey: cacheTemperatureKey) != nil else {
            return nil
        }

        return WeatherContext(
            weatherCode: userDefaults.integer(forKey: cacheWeatherCodeKey),
            temperatureCelsius: userDefaults.double(forKey: cacheTemperatureKey)
        )
    }

    private static let cacheWeatherCodeKey = "weather.cache.code"
    private static let cacheTemperatureKey = "weather.cache.temperature"
    private static let cacheTimestampKey = "weather.cache.timestamp"
    private static let fallbackWeather = WeatherContext(weatherCode: 2, temperatureCelsius: 20)
}

@MainActor
final class CachedLocationSnapshotStore: NSObject, CLLocationManagerDelegate {
    private(set) var currentCoordinates: WeatherCoordinates?
    private(set) var lastUpdatedAt: Date?

    private let manager: CLLocationManager
    private let userDefaults: UserDefaults
    private var locationContinuation: CheckedContinuation<WeatherCoordinates?, Never>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    init(
        manager: CLLocationManager = CLLocationManager(),
        userDefaults: UserDefaults = .standard
    ) {
        self.manager = manager
        self.userDefaults = userDefaults
        self.currentCoordinates = Self.readCachedCoordinates(from: userDefaults) ?? .prototypeFallback
        self.lastUpdatedAt = userDefaults.object(forKey: Self.cacheTimestampKey) as? Date
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func refreshIfNeeded(maxAge: TimeInterval = 60 * 60) async {
        if let lastUpdatedAt, Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }

        await refresh()
    }

    func refresh() async {
        let status = await resolvedAuthorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if let coordinates = await requestLocation() {
                apply(coordinates, at: Date())
            } else {
                applyFallbackIfNeeded()
            }
        case .denied, .restricted:
            applyFallbackIfNeeded()
        case .notDetermined:
            applyFallbackIfNeeded()
        @unknown default:
            applyFallbackIfNeeded()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationContinuation?.resume(returning: manager.authorizationStatus)
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let coordinates = location.map {
            WeatherCoordinates(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        locationContinuation?.resume(returning: coordinates)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    private func resolvedAuthorizationStatus() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else {
            return status
        }

        manager.requestWhenInUseAuthorization()
        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
        }
    }

    private func requestLocation() async -> WeatherCoordinates? {
        manager.requestLocation()
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
        }
    }

    private func apply(_ coordinates: WeatherCoordinates, at timestamp: Date) {
        currentCoordinates = coordinates
        lastUpdatedAt = timestamp
        userDefaults.set(coordinates.latitude, forKey: Self.cacheLatitudeKey)
        userDefaults.set(coordinates.longitude, forKey: Self.cacheLongitudeKey)
        userDefaults.set(timestamp, forKey: Self.cacheTimestampKey)
    }

    private func applyFallbackIfNeeded() {
        if currentCoordinates == nil {
            apply(.prototypeFallback, at: Date())
        }
    }

    private static func readCachedCoordinates(from userDefaults: UserDefaults) -> WeatherCoordinates? {
        guard userDefaults.object(forKey: cacheLatitudeKey) != nil,
              userDefaults.object(forKey: cacheLongitudeKey) != nil else {
            return nil
        }

        return WeatherCoordinates(
            latitude: userDefaults.double(forKey: cacheLatitudeKey),
            longitude: userDefaults.double(forKey: cacheLongitudeKey)
        )
    }

    private static let cacheLatitudeKey = "location.cache.latitude"
    private static let cacheLongitudeKey = "location.cache.longitude"
    private static let cacheTimestampKey = "location.cache.timestamp"
}

private struct OpenMeteoWeatherResponse: Decodable {
    let currentWeather: OpenMeteoCurrentWeather

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
    }
}

private struct OpenMeteoCurrentWeather: Decodable {
    let temperature: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case weatherCode = "weathercode"
    }
}
