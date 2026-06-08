import Foundation
import Combine

protocol RemoteSongService {
    func fetchSongs(for profile: SongSelectionProfile, limit: Int) async throws -> [Song]
}

struct JamendoSongService: RemoteSongService {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSongs(for profile: SongSelectionProfile, limit: Int = 20) async throws -> [Song] {
        if let filteredSongs = try await searchSongs(
            tag: profile.weatherTag,
            speed: profile.speed.jamendoValue,
            limit: limit
        ), !filteredSongs.isEmpty {
            return filteredSongs
        }

        if let tagOnlySongs = try await searchSongs(
            tag: profile.weatherTag,
            speed: nil,
            limit: limit
        ), !tagOnlySongs.isEmpty {
            return tagOnlySongs
        }

        return try await searchSongs(tag: nil, speed: nil, limit: limit) ?? []
    }

    private func searchSongs(tag: String?, speed: String?, limit: Int) async throws -> [Song]? {
        var components = URLComponents(string: "https://api.jamendo.com/v3.0/tracks/")
        components?.queryItems = buildQueryItems(tag: tag, speed: speed, limit: limit)

        guard let url = components?.url else {
            throw JamendoSongServiceError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(JamendoTracksResponse.self, from: data)
        let songs = response.results.compactMap(\.song)
        return songs.isEmpty ? nil : songs
    }

    private func buildQueryItems(tag: String?, speed: String?, limit: Int) -> [URLQueryItem] {
        let randomOffset = Int.random(in: 0 ... 120)

        var items = [
            URLQueryItem(name: "client_id", value: JamendoConfig.clientID),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(randomOffset)),
            URLQueryItem(name: "vocalinstrumental", value: "instrumental"),
            URLQueryItem(name: "durationbetween", value: "60_600"),
            URLQueryItem(name: "audioformat", value: "mp32"),
            URLQueryItem(name: "imagesize", value: "400"),
            URLQueryItem(name: "include", value: "musicinfo")
        ]

        if let tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "fuzzytags", value: tag))
        }

        if let speed, !speed.isEmpty {
            items.append(URLQueryItem(name: "speed", value: speed))
        }

        return items
    }
}

enum JamendoConfig {
    static let clientID = "8e61e407"
}

enum JamendoSongServiceError: Error {
    case invalidURL
}

@MainActor
protocol SongPoolSnapshotProviding {
    func songs(for profile: SongSelectionProfile) -> [Song]
}

@MainActor
final class CachedRemoteSongPoolStore: ObservableObject, SongPoolSnapshotProviding {
    @Published private var songsByProfileKey: [String: [Song]] = [:]

    private let service: RemoteSongService
    private var lastUpdatedAtByProfileKey: [String: Date] = [:]

    init() {
        self.service = JamendoSongService()
    }

    init(service: RemoteSongService) {
        self.service = service
    }

    func songs(for profile: SongSelectionProfile) -> [Song] {
        songsByProfileKey[profile.cacheKey] ?? []
    }

    func refreshIfNeeded(for profile: SongSelectionProfile, maxAge: TimeInterval = 30 * 60) async {
        if let lastUpdatedAt = lastUpdatedAtByProfileKey[profile.cacheKey],
           Date().timeIntervalSince(lastUpdatedAt) < maxAge {
            return
        }

        await refresh(for: profile)
    }

    func forceRefresh(for profile: SongSelectionProfile) async {
        lastUpdatedAtByProfileKey[profile.cacheKey] = nil
        await refresh(for: profile)
    }

    func refresh(for profile: SongSelectionProfile) async {
        do {
            let songs = try await service.fetchSongs(for: profile, limit: 8)
            guard !songs.isEmpty else { return }
            songsByProfileKey[profile.cacheKey] = songs
            lastUpdatedAtByProfileKey[profile.cacheKey] = Date()
        } catch {
            return
        }
    }
}

private struct JamendoTracksResponse: Decodable {
    let results: [JamendoTrack]
}

private struct JamendoTrack: Decodable {
    let id: String
    let name: String
    let artistName: String
    let image: String?
    let audio: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            self.id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intID)
        } else {
            self.id = UUID().uuidString
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.artistName = try container.decode(String.self, forKey: .artistName)
        self.image = try? container.decode(String.self, forKey: .image)
        self.audio = try? container.decode(String.self, forKey: .audio)
    }

    var song: Song? {
        Song(
            id: id,
            title: name,
            artist: artistName,
            artworkURL: image.flatMap(URL.init(string:)),
            audioURL: audio.flatMap(URL.init(string:))
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artistName = "artist_name"
        case image
        case audio
    }
}
