import Foundation

protocol LocalDataStore {
    func loadAlarms() -> [Alarm]
    func saveAlarms(_ alarms: [Alarm])
    func loadFavoriteSongs() -> [Song]
    func saveFavoriteSongs(_ songs: [Song])
}

struct UserDefaultsLocalDataStore: LocalDataStore {
    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadAlarms() -> [Alarm] {
        decode([Alarm].self, forKey: Keys.alarms) ?? []
    }

    func saveAlarms(_ alarms: [Alarm]) {
        encode(alarms, forKey: Keys.alarms)
    }

    func loadFavoriteSongs() -> [Song] {
        decode([Song].self, forKey: Keys.favoriteSongs) ?? []
    }

    func saveFavoriteSongs(_ songs: [Song]) {
        encode(songs, forKey: Keys.favoriteSongs)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? decoder.decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }

    private enum Keys {
        static let alarms = "local-data-store.alarms"
        static let favoriteSongs = "local-data-store.favorite-songs"
    }
}
