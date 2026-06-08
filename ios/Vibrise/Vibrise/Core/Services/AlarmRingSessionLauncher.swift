import Foundation

@MainActor
final class AlarmRingSessionLauncher {
    private let runtimeCoordinator: AlarmRuntimeCoordinator
    private let weatherSnapshotStore: CachedWeatherSnapshotStore
    private let remoteSongPoolStore: CachedRemoteSongPoolStore
    private let songProfileResolver: SongProfileResolving

    init(
        runtimeCoordinator: AlarmRuntimeCoordinator,
        weatherSnapshotStore: CachedWeatherSnapshotStore,
        remoteSongPoolStore: CachedRemoteSongPoolStore,
        songProfileResolver: SongProfileResolving
    ) {
        self.runtimeCoordinator = runtimeCoordinator
        self.weatherSnapshotStore = weatherSnapshotStore
        self.remoteSongPoolStore = remoteSongPoolStore
        self.songProfileResolver = songProfileResolver
    }

    func launch(
        alarm: Alarm,
        triggerDate: Date,
        forceRefresh: Bool = false
    ) async {
        let profile = songProfileResolver.resolveProfile(
            for: alarm,
            now: triggerDate,
            weather: weatherSnapshotStore.currentWeather
        )

        if forceRefresh {
            await remoteSongPoolStore.forceRefresh(for: profile)
        } else {
            await remoteSongPoolStore.refreshIfNeeded(for: profile)
        }

        runtimeCoordinator.startSession(alarm: alarm, now: triggerDate)
    }
}
