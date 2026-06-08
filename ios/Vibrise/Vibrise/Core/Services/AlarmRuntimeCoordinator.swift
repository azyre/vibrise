import Foundation
import Combine

@MainActor
final class AlarmRuntimeCoordinator: ObservableObject {
    @Published private(set) var activeRingSession: RingSession?
    @Published private(set) var pendingSnoozeSession: PendingSnoozeSession?
    @Published private(set) var transientMessage: String?
    private let songSelectionService: SongSelectionService

    init() {
        self.songSelectionService = DefaultSongSelectionService()
    }

    init(songSelectionService: SongSelectionService) {
        self.songSelectionService = songSelectionService
    }

    func startSession(alarm: Alarm, now: Date = Date()) {
        let song = songSelectionService.pickSong(for: alarm, now: now)
        activeRingSession = RingSession(alarm: alarm, song: song)
    }

    func startPendingSnoozeSession(_ session: PendingSnoozeSession) {
        pendingSnoozeSession = nil
        activeRingSession = RingSession(alarm: session.alarm, song: session.song)
    }

    func dismissActiveSession() {
        guard activeRingSession != nil else { return }
        activeRingSession = nil
        transientMessage = "Alarm dismissed"
    }

    func snoozeActiveSession(minutes: Int, now: Date = Date(), calendar: Calendar = .current) {
        guard let session = activeRingSession else { return }
        let triggerDate = calendar.date(byAdding: .minute, value: minutes, to: now) ?? now
        pendingSnoozeSession = PendingSnoozeSession(
            alarm: session.alarm,
            song: session.song,
            triggerDate: triggerDate
        )
        activeRingSession = nil
        transientMessage = "Snoozed to \(formattedTime(triggerDate, calendar: calendar))"
    }

    func clearTransientMessage() {
        transientMessage = nil
    }

    func showTransientMessage(_ message: String) {
        transientMessage = message
    }

    func nextPendingSnoozeDate(now: Date = Date()) -> Date? {
        guard let pendingSnoozeSession, pendingSnoozeSession.triggerDate >= now else {
            return nil
        }
        return pendingSnoozeSession.triggerDate
    }

    func duePendingSnoozeSession(now: Date = Date(), calendar: Calendar = .current) -> PendingSnoozeSession? {
        guard let pendingSnoozeSession else { return nil }
        let startOfCurrentMinute = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let endOfCurrentMinute = calendar.date(byAdding: .minute, value: 1, to: startOfCurrentMinute) ?? now

        guard pendingSnoozeSession.triggerDate >= startOfCurrentMinute,
              pendingSnoozeSession.triggerDate < endOfCurrentMinute else {
            return nil
        }

        return pendingSnoozeSession
    }

    private func formattedTime(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
