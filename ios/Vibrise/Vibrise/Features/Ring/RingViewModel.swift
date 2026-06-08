import Foundation
import Combine

@MainActor
final class RingViewModel: ObservableObject {
    @Published private(set) var alarm: Alarm
    @Published private(set) var song: Song
    @Published var isFavorited = false
    @Published var transientMessage: String?
    @Published private(set) var isPlayingAudio = false
    private let audioPlayer: AlarmAudioPlaying
    private var isCompletingAlarmAction = false

    init(alarm: Alarm, song: Song, isFavorited: Bool = false) {
        self.alarm = alarm
        self.song = song
        self.isFavorited = isFavorited
        self.audioPlayer = AlarmAudioPlayer()
        self.audioPlayer.onPlaybackEvent = { [weak self] event in
            self?.handlePlaybackEvent(event)
        }
    }

    var ringTimeText: String {
        alarm.displayTime
    }

    var ringDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE MMMM d"
        return formatter.string(from: Date())
    }

    var shareMonthText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    var shareDayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    var shareText: String {
        "\(song.title) by \(song.artist) woke me up with Vibrise at \(alarm.displayTime)."
    }

    func toggleFavorite() {
        isFavorited.toggle()
        transientMessage = isFavorited ? "Added to favorites" : "Removed from favorites"
    }

    func handleSnooze() {
        isCompletingAlarmAction = true
        stopPlayback()
        transientMessage = "Snoozed for 10 minutes"
    }

    func handleDismiss() {
        isCompletingAlarmAction = true
        stopPlayback()
        transientMessage = "Alarm dismissed"
    }

    func handleCoffeeTap() {
        transientMessage = "Opening Buy me a coffee"
    }

    func showTransientMessage(_ message: String) {
        transientMessage = message
    }

    func clearTransientMessage() {
        transientMessage = nil
    }

    func startPlayback() {
        guard !isPlayingAudio, !isCompletingAlarmAction else {
            return
        }

        do {
            try audioPlayer.startPlayback(for: song)
            isPlayingAudio = true
        } catch {
            isPlayingAudio = false
            transientMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        audioPlayer.stopPlayback()
        isPlayingAudio = false
    }

    func recoverPlaybackIfNeeded() {
        if !isPlayingAudio, !isCompletingAlarmAction {
            startPlayback()
        }
    }

    private func handlePlaybackEvent(_ event: AlarmAudioPlaybackEvent) {
        switch event {
        case .started, .resumed:
            isPlayingAudio = true
        case .paused, .stopped:
            isPlayingAudio = false
        case .failed(let message):
            isPlayingAudio = false
            transientMessage = message
        }
    }
}
