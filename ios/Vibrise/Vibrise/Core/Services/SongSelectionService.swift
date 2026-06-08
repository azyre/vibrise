import Foundation

@MainActor
protocol SongSelectionService {
    func pickSong(for alarm: Alarm, now: Date) -> Song
}

@MainActor
protocol WeatherSnapshotProviding {
    var currentWeather: WeatherContext? { get }
}

struct SongSelectionProfile: Equatable {
    let strategyID: String
    let speed: SpeedBucket
    let weatherTag: String?

    var cacheKey: String {
        "\(strategyID)|\(speed.rawValue)|\(weatherTag ?? "none")"
    }

    enum SpeedBucket: String, Equatable {
        case veryLow
        case low
        case medium
        case high

        var jamendoValue: String {
            switch self {
            case .veryLow: return "verylow"
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            }
        }
    }
}

protocol SongProfileResolving {
    func resolveProfile(for alarm: Alarm, now: Date, weather: WeatherContext?) -> SongSelectionProfile
}

protocol SongRepository {
    func songs(for profile: SongSelectionProfile) -> [Song]
}

@MainActor
final class DefaultSongSelectionService: SongSelectionService {
    private let profileResolver: SongProfileResolving
    private let repository: SongRepository
    private let weatherProvider: WeatherSnapshotProviding?
    private var lastSelectedSongIDByProfileKey: [String: String] = [:]

    init() {
        self.profileResolver = WeatherTimeSongProfileResolver()
        self.repository = CuratedSongRepository()
        self.weatherProvider = nil
    }

    init(
        profileResolver: SongProfileResolving,
        repository: SongRepository,
        weatherProvider: WeatherSnapshotProviding? = nil
    ) {
        self.profileResolver = profileResolver
        self.repository = repository
        self.weatherProvider = weatherProvider
    }

    func pickSong(for alarm: Alarm, now: Date = Date()) -> Song {
        let profile = profileResolver.resolveProfile(for: alarm, now: now, weather: weatherProvider?.currentWeather)
        let songs = repository.songs(for: profile)
        let previousSongID = lastSelectedSongIDByProfileKey[profile.cacheKey]
        let candidateSongs = songs.count > 1
            ? songs.filter { $0.id != previousSongID }
            : songs
        let selectedSong = candidateSongs.randomElement() ?? songs[0]
        lastSelectedSongIDByProfileKey[profile.cacheKey] = selectedSong.id
        return selectedSong
    }
}

struct WeatherTimeSongProfileResolver: SongProfileResolving {
    func resolveProfile(for alarm: Alarm, now: Date, weather: WeatherContext?) -> SongSelectionProfile {
        SongSelectionProfile(
            strategyID: "weather-time",
            speed: speedBucket(for: now),
            weatherTag: weatherTag(for: weather)
        )
    }

    private func speedBucket(for date: Date) -> SongSelectionProfile.SpeedBucket {
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 5 { return .veryLow }
        if hour < 7 { return .low }
        if hour < 11 { return .medium }
        if hour < 18 { return .high }
        if hour < 21 { return .medium }
        return .low
    }

    private func weatherTag(for weather: WeatherContext?) -> String {
        guard let weather else {
            return WeatherCatalog.defaultWeatherTag
        }
        return WeatherCatalog.info(for: weather.weatherCode).tag
    }
}

struct CuratedSongRepository: SongRepository {
    func songs(for profile: SongSelectionProfile) -> [Song] {
        let weatherSongs = songsByWeatherTag(profile.weatherTag)
        let bySpeed = songsBySpeed(profile.speed)
        let combined = mergeUnique(primary: weatherSongs, secondary: bySpeed)
        return combined.isEmpty ? fallbackSongs : combined
    }

    private func songsBySpeed(_ speed: SongSelectionProfile.SpeedBucket) -> [Song] {
        switch speed {
        case .veryLow:
            return [.winterSilence, .rainyThoughts]
        case .low:
            return [.gentleAwakening, .forestWalk]
        case .medium:
            return [.mockMorningLight, .gentleAwakening, .forestWalk]
        case .high:
            return [.electricSunrise, .mockMorningLight]
        }
    }

    private func songsByWeatherTag(_ tag: String?) -> [Song] {
        switch tag {
        case "happy":
            return [.electricSunrise, .mockMorningLight]
        case "lounge+downtempo":
            return [.mockMorningLight, .forestWalk]
        case "chillout":
            return [.forestWalk, .gentleAwakening]
        case "atmospheric":
            return [.winterSilence, .forestWalk]
        case "lofi+chillhop":
            return [.rainyThoughts, .gentleAwakening]
        case "jazz":
            return [.rainyThoughts, .mockMorningLight]
        case "cinematic":
            return [.winterSilence, .electricSunrise]
        case "soft":
            return [.gentleAwakening, .winterSilence]
        case "newage":
            return [.winterSilence, .forestWalk]
        case "epic+adventure":
            return [.electricSunrise, .winterSilence]
        default:
            return []
        }
    }

    private func mergeUnique(primary: [Song], secondary: [Song]) -> [Song] {
        var seen = Set<String>()
        var merged: [Song] = []

        for song in primary + secondary {
            if seen.insert(song.id).inserted {
                merged.append(song)
            }
        }

        return merged
    }

    private var fallbackSongs: [Song] {
        [.mockMorningLight, .gentleAwakening, .forestWalk, .rainyThoughts, .electricSunrise]
    }
}

@MainActor
struct HybridSongRepository: SongRepository {
    private let remoteStore: SongPoolSnapshotProviding
    private let fallbackRepository: SongRepository

    init(remoteStore: SongPoolSnapshotProviding) {
        self.remoteStore = remoteStore
        self.fallbackRepository = CuratedSongRepository()
    }

    init(
        remoteStore: SongPoolSnapshotProviding,
        fallbackRepository: SongRepository
    ) {
        self.remoteStore = remoteStore
        self.fallbackRepository = fallbackRepository
    }

    func songs(for profile: SongSelectionProfile) -> [Song] {
        let remoteSongs = remoteStore.songs(for: profile)
        let fallbackSongs = fallbackRepository.songs(for: profile)
        let combined = mergeUniqueSongs(primary: remoteSongs, secondary: fallbackSongs)
        return combined.isEmpty ? fallbackSongs : combined
    }
}

private func mergeUniqueSongs(primary: [Song], secondary: [Song]) -> [Song] {
    var seen = Set<String>()
    var merged: [Song] = []

    for song in primary + secondary {
        if seen.insert(song.id).inserted {
            merged.append(song)
        }
    }

    return merged
}
