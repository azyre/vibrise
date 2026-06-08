import Foundation

struct HomeViewModelDependencies {
    let runtimeCoordinator: AlarmRuntimeCoordinator
    let weatherSnapshotStore: CachedWeatherSnapshotStore
    let remoteSongPoolStore: CachedRemoteSongPoolStore
    let songProfileResolver: SongProfileResolving
    let localDataStore: LocalDataStore
    let ringSessionLauncher: AlarmRingSessionLauncher
    let ringLaunchCoordinator: AlarmRingLaunchCoordinator

    static func makeDefault() -> HomeViewModelDependencies {
        let localDataStore = UserDefaultsLocalDataStore()
        let weatherSnapshotStore = CachedWeatherSnapshotStore()
        let remoteSongPoolStore = CachedRemoteSongPoolStore()
        let songProfileResolver = WeatherTimeSongProfileResolver()
        let runtimeCoordinator = AlarmRuntimeCoordinator(
            songSelectionService: DefaultSongSelectionService(
                profileResolver: songProfileResolver,
                repository: HybridSongRepository(remoteStore: remoteSongPoolStore),
                weatherProvider: weatherSnapshotStore
            )
        )

        return makeConfigured(
            runtimeCoordinator: runtimeCoordinator,
            weatherSnapshotStore: weatherSnapshotStore,
            remoteSongPoolStore: remoteSongPoolStore,
            songProfileResolver: songProfileResolver,
            localDataStore: localDataStore
        )
    }

    static func makeConfigured(
        runtimeCoordinator: AlarmRuntimeCoordinator,
        weatherSnapshotStore: CachedWeatherSnapshotStore,
        remoteSongPoolStore: CachedRemoteSongPoolStore,
        songProfileResolver: SongProfileResolving,
        localDataStore: LocalDataStore
    ) -> HomeViewModelDependencies {
        HomeViewModelDependencies(
            runtimeCoordinator: runtimeCoordinator,
            weatherSnapshotStore: weatherSnapshotStore,
            remoteSongPoolStore: remoteSongPoolStore,
            songProfileResolver: songProfileResolver,
            localDataStore: localDataStore,
            ringSessionLauncher: AlarmRingSessionLauncher(
                runtimeCoordinator: runtimeCoordinator,
                weatherSnapshotStore: weatherSnapshotStore,
                remoteSongPoolStore: remoteSongPoolStore,
                songProfileResolver: songProfileResolver
            ),
            ringLaunchCoordinator: AlarmRingLaunchCoordinator()
        )
    }
}
