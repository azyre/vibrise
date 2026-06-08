import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    private struct InitialState {
        let alarms: [Alarm]
        let favoriteSongs: [Song]
        let nextAlarmID: Int
    }

    @Published var alarms: [Alarm]
    @Published var favoriteSongs: [Song] = []
    @Published var activeRingSession: RingSession?
    @Published var transientMessage: String?
    @Published var nextAlarmSummary: String?
    @Published private(set) var shouldAutoPresentDonationOnRing = false
    @Published private(set) var homeBackgroundStyle = HomeBackgroundStyle.make(weather: nil)
    @Published private(set) var albumCoverImageData: Data?
    let homeBackgroundSeed: UInt64

    private var nextAlarmID = 2
    private let runtimeCoordinator: AlarmRuntimeCoordinator
    private let weatherSnapshotStore: CachedWeatherSnapshotStore
    private let remoteSongPoolStore: CachedRemoteSongPoolStore
    private let songProfileResolver: SongProfileResolving
    private let localDataStore: LocalDataStore
    private let ringSessionLauncher: AlarmRingSessionLauncher
    private let ringLaunchCoordinator: AlarmRingLaunchCoordinator
    private var cancellables = Set<AnyCancellable>()
    private var lastTriggeredTriggerKey: String?
    private var lastPrefetchedSongProfileKey: String?
    private var isAlbumCoverOverrideActive = false

    convenience init() {
        self.init(
            homeBackgroundSeed: UInt64.random(in: 0 ... UInt64.max),
            dependencies: .makeDefault()
        )
    }

    convenience init(
        runtimeCoordinator: AlarmRuntimeCoordinator,
        weatherSnapshotStore: CachedWeatherSnapshotStore,
        remoteSongPoolStore: CachedRemoteSongPoolStore,
        songProfileResolver: SongProfileResolving,
        localDataStore: LocalDataStore
    ) {
        self.init(
            homeBackgroundSeed: UInt64.random(in: 0 ... UInt64.max),
            dependencies: .makeConfigured(
                runtimeCoordinator: runtimeCoordinator,
                weatherSnapshotStore: weatherSnapshotStore,
                remoteSongPoolStore: remoteSongPoolStore,
                songProfileResolver: songProfileResolver,
                localDataStore: localDataStore
            )
        )
    }

    // MARK: - Public Actions

    func makeNewAlarmDraft() -> Alarm {
        Alarm(
            id: nextAlarmID,
            isEnabled: true,
            hour: 7,
            minute: 0,
            repeatDays: [1, 2, 3, 4, 5]
        )
    }

    func save(_ alarm: Alarm) {
        if let existingIndex = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[existingIndex] = alarm
        } else {
            alarms.append(alarm)
            nextAlarmID += 1
        }

        alarms = Self.normalizeAlarms(alarms)
        persistAlarms()
        syncAlarmNotifications()

        refreshScheduleState(now: Date())
    }

    func toggleAlarm(_ alarmID: Int, isEnabled: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == alarmID }) else { return }
        alarms[index].isEnabled = isEnabled
        persistAlarms()
        syncAlarmNotifications()
        refreshScheduleState(now: Date())
    }

    func startTestingAlarm(_ alarm: Alarm) {
        triggerRingSession(for: alarm, triggerDate: Date(), forceRefresh: true)
    }

    func dismissActiveRingSession() {
        runtimeCoordinator.dismissActiveSession()
    }

    func snoozeActiveRingSession(minutes: Int) {
        runtimeCoordinator.snoozeActiveSession(minutes: minutes)
        refreshScheduleState(now: Date())
    }

    func applyAlbumCoverBackgroundStyle(_ style: HomeBackgroundStyle, artworkData: Data? = nil) {
        homeBackgroundStyle = style
        albumCoverImageData = artworkData
        isAlbumCoverOverrideActive = true
    }

    func isFavorite(_ song: Song) -> Bool {
        favoriteSongs.contains(song)
    }

    func toggleFavorite(song: Song) {
        if let index = favoriteSongs.firstIndex(of: song) {
            favoriteSongs.remove(at: index)
            runtimeCoordinator.showTransientMessage("Removed from favorites")
        } else {
            favoriteSongs.insert(song, at: 0)
            runtimeCoordinator.showTransientMessage("Added to favorites")
        }
        persistFavoriteSongs()
    }

    func clearTransientMessage() {
        runtimeCoordinator.clearTransientMessage()
    }

    func handleSceneBecameActive() {
        handlePendingOpenRingRequestIfNeeded()
        syncAlarmNotifications()
        refreshScheduleState(now: Date())
        refreshHomeBackgroundStyle(now: Date())
        refreshWeatherSnapshotIfNeeded()
    }

    // MARK: - Bindings

    private func bindRuntimeCoordinator() {
        runtimeCoordinator.$activeRingSession
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                guard let self else { return }
                self.activeRingSession = session
            }
            .store(in: &cancellables)

        runtimeCoordinator.$transientMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                self?.transientMessage = message
            }
            .store(in: &cancellables)
    }

    private func bindClock() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.refreshScheduleState(now: now)
            }
            .store(in: &cancellables)
    }

    private func bindOpenRingRequests() {
        ringLaunchCoordinator.start { [weak self] request in
            self?.handleRingLaunchRequest(request)
        }
    }

    // MARK: - Scheduling And Background

    private func refreshScheduleState(now: Date) {
        updateNextAlarmSummary(now: now)

        prefetchSongPoolIfNeeded(now: now)

        guard activeRingSession == nil else {
            return
        }

        if handleDuePendingSnoozeIfNeeded(now: now) {
            return
        }

        guard let dueOccurrence = ForegroundAlarmTriggerService.dueOccurrence(
            from: alarms,
            now: now,
            lastTriggeredTriggerKey: lastTriggeredTriggerKey,
            isSystemAlarmAuthorized: AlarmKitSchedulingService.isSystemAlarmAuthorized
        ) else {
            return
        }

        lastTriggeredTriggerKey = dueOccurrence.triggerKey
        triggerRingSession(for: dueOccurrence.alarm, triggerDate: dueOccurrence.triggerDate)
        updateNextAlarmSummary(now: now)
    }

    private func formattedNextAlarm(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE HH:mm"
        return formatter.string(from: date)
    }

    private func refreshWeatherSnapshotIfNeeded() {
        Task { [weak self] in
            await self?.weatherSnapshotStore.refreshIfNeeded()
            await MainActor.run {
                self?.refreshHomeBackgroundStyle(now: Date())
                self?.prefetchSongPoolIfNeeded(now: Date())
            }
        }
    }

    private func refreshHomeBackgroundStyle(now: Date) {
        guard activeRingSession == nil else { return }
        guard !isAlbumCoverOverrideActive else { return }
        let style = HomeBackgroundStyle.make(
            weather: weatherSnapshotStore.currentWeather,
            now: now
        )
        homeBackgroundStyle = style
    }

    private func clearAlbumCoverOverride() {
        isAlbumCoverOverrideActive = false
        albumCoverImageData = nil
    }

    // MARK: - Persistence And Prefetch

    private func persistAlarms() {
        localDataStore.saveAlarms(alarms)
    }

    private func persistFavoriteSongs() {
        localDataStore.saveFavoriteSongs(favoriteSongs)
    }

    private func prefetchSongPoolIfNeeded(now: Date) {
        let referenceAlarm = alarms.first(where: { $0.isEnabled }) ?? alarms.first ?? .mockWeekdayMorning
        let profile = songProfileResolver.resolveProfile(
            for: referenceAlarm,
            now: now,
            weather: weatherSnapshotStore.currentWeather
        )

        guard profile.cacheKey != lastPrefetchedSongProfileKey else { return }
        lastPrefetchedSongProfileKey = profile.cacheKey

        Task { [weak self] in
            await self?.remoteSongPoolStore.refreshIfNeeded(for: profile)
        }
    }

    private func updateNextAlarmSummary(now: Date) {
        let nextScheduledDate = AlarmSchedulingService.nextScheduledOccurrence(from: alarms, now: now)?.triggerDate
        let nextSnoozeDate = runtimeCoordinator.nextPendingSnoozeDate(now: now)

        let nextDate = [nextScheduledDate, nextSnoozeDate]
            .compactMap { $0 }
            .min()

        if let nextDate {
            nextAlarmSummary = "Next: \(formattedNextAlarm(nextDate))"
        } else {
            nextAlarmSummary = nil
        }
    }

    // MARK: - Initialization

    private static func normalizeAlarms(_ alarms: [Alarm]) -> [Alarm] {
        alarms.sorted { lhs, rhs in
            if lhs.hour == rhs.hour {
                return lhs.minute < rhs.minute
            }
            return lhs.hour < rhs.hour
        }
    }

    private init(homeBackgroundSeed: UInt64, dependencies: HomeViewModelDependencies) {
        self.homeBackgroundSeed = homeBackgroundSeed
        self.runtimeCoordinator = dependencies.runtimeCoordinator
        self.weatherSnapshotStore = dependencies.weatherSnapshotStore
        self.remoteSongPoolStore = dependencies.remoteSongPoolStore
        self.songProfileResolver = dependencies.songProfileResolver
        self.localDataStore = dependencies.localDataStore
        self.ringSessionLauncher = dependencies.ringSessionLauncher
        self.ringLaunchCoordinator = dependencies.ringLaunchCoordinator

        let initialState = Self.makeInitialState(using: dependencies.localDataStore)
        self.alarms = initialState.alarms
        self.favoriteSongs = initialState.favoriteSongs
        self.nextAlarmID = initialState.nextAlarmID

        performInitialSetup(now: Date())
    }

    private func performInitialSetup(now: Date) {
        bindRuntimeCoordinator()
        bindClock()
        bindOpenRingRequests()
        handlePendingOpenRingRequestIfNeeded()
        syncAlarmNotifications()
        refreshScheduleState(now: now)
        refreshHomeBackgroundStyle(now: now)
        refreshWeatherSnapshotIfNeeded()
        prefetchSongPoolIfNeeded(now: now)
    }

    // MARK: - Ring Launch

    private func syncAlarmNotifications() {
        let currentAlarms = alarms
        Task { [weak self] in
            let result = await AlarmScheduleSyncService.sync(alarms: currentAlarms)

            await MainActor.run {
                if let message = AlarmScheduleSyncFeedback.message(for: result) {
                    self?.runtimeCoordinator.showTransientMessage(message)
                }
            }
        }
    }

    private func handlePendingOpenRingRequestIfNeeded() {
        guard let request = ringLaunchCoordinator.consumePendingRequestIfNeeded() else {
            return
        }

        handleRingLaunchRequest(request)
    }

    func consumeAutoPresentDonationOnRing() -> Bool {
        let shouldAutoPresentDonation = shouldAutoPresentDonationOnRing
        shouldAutoPresentDonationOnRing = false
        return shouldAutoPresentDonation
    }

    private func handleRingLaunchRequest(_ request: PendingRingLaunchRequest) {
        openRingView(
            for: request.alarmID,
            autoPresentDonation: request.autoPresentDonation
        )
    }

    private func openRingView(for alarmID: Int, autoPresentDonation: Bool) {
        guard let alarm = alarms.first(where: { $0.id == alarmID }) else {
            runtimeCoordinator.showTransientMessage("That alarm is no longer available")
            return
        }

        triggerRingSession(
            for: alarm,
            triggerDate: Date(),
            forceRefresh: true,
            autoPresentDonation: autoPresentDonation
        )
    }

    private func triggerRingSession(
        for alarm: Alarm,
        triggerDate: Date,
        forceRefresh: Bool = false,
        autoPresentDonation: Bool = false
    ) {
        clearAlbumCoverOverride()
        shouldAutoPresentDonationOnRing = autoPresentDonation
        Task { [weak self] in
            guard let self else { return }
            await ringSessionLauncher.launch(
                alarm: alarm,
                triggerDate: triggerDate,
                forceRefresh: forceRefresh
            )
        }
    }

    private func handleDuePendingSnoozeIfNeeded(now: Date) -> Bool {
        guard let duePendingSnoozeSession = runtimeCoordinator.duePendingSnoozeSession(now: now),
              duePendingSnoozeSession.triggerKey != lastTriggeredTriggerKey else {
            return false
        }

        lastTriggeredTriggerKey = duePendingSnoozeSession.triggerKey
        clearAlbumCoverOverride()
        runtimeCoordinator.startPendingSnoozeSession(duePendingSnoozeSession)
        updateNextAlarmSummary(now: now)
        return true
    }

    private static func makeInitialState(using localDataStore: LocalDataStore) -> InitialState {
        let loadedAlarms = localDataStore.loadAlarms()
        let normalizedAlarms = Self.normalizeAlarms(loadedAlarms.isEmpty ? [.mockWeekdayMorning] : loadedAlarms)
        let favoriteSongs = localDataStore.loadFavoriteSongs()
        let nextAlarmID = (normalizedAlarms.map(\.id).max() ?? 0) + 1

        return InitialState(
            alarms: normalizedAlarms,
            favoriteSongs: favoriteSongs,
            nextAlarmID: nextAlarmID
        )
    }
}
