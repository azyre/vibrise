import Foundation
import UserNotifications

enum AlarmNotificationService {
    enum SyncResult {
        case scheduled
        case unauthorized
        case failed
    }

    private static let alarmIdentifierPrefix = "alarm."
    static let alarmIDUserInfoKey = "alarmID"
    private static let bundledSoundFilename = "alarm_chime.wav"

    static func alarmID(from userInfo: [AnyHashable: Any]) -> Int? {
        if let alarmID = userInfo[alarmIDUserInfoKey] as? Int {
            return alarmID
        }

        if let alarmIDString = userInfo[alarmIDUserInfoKey] as? String {
            return Int(alarmIDString)
        }

        return nil
    }

    static func clearSyncedNotifications() async {
        await removeAlarmNotifications(from: UNUserNotificationCenter.current())
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await notificationSettings(for: center)

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await requestAuthorization(from: center)) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func syncNotifications(
        for alarms: [Alarm],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async -> SyncResult {
        let center = UNUserNotificationCenter.current()

        guard await requestAuthorizationIfNeeded() else {
            await removeAlarmNotifications(from: center)
            return .unauthorized
        }

        await removeAlarmNotifications(from: center)

        let enabledAlarms = alarms.filter(\.isEnabled)
        do {
            for alarm in enabledAlarms {
                for request in notificationRequests(for: alarm, now: now, calendar: calendar) {
                    try await add(request, to: center)
                }
            }

            return .scheduled
        } catch {
            return .failed
        }
    }

    private static func notificationRequests(
        for alarm: Alarm,
        now: Date,
        calendar: Calendar
    ) -> [UNNotificationRequest] {
        if alarm.repeatDays.isEmpty {
            guard let triggerDate = AlarmSchedulingService.nextOccurrence(for: alarm, now: now, calendar: calendar) else {
                return []
            }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            return [
                UNNotificationRequest(
                    identifier: "\(alarmIdentifierPrefix)\(alarm.id).once",
                    content: notificationContent(for: alarm),
                    trigger: trigger
                )
            ]
        }

        return alarm.sortedRepeatDays.map { dayIndex in
            var components = DateComponents()
            components.weekday = dayIndex + 1
            components.hour = alarm.hour
            components.minute = alarm.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            return UNNotificationRequest(
                identifier: "\(alarmIdentifierPrefix)\(alarm.id).weekday.\(dayIndex)",
                content: notificationContent(for: alarm),
                trigger: trigger
            )
        }
    }

    private static func notificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Vibrise"
        content.body = "It's \(alarm.displayTime). Time to wake up."
        if let bundledSoundName = bundledSoundName() {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: bundledSoundName))
        } else {
            content.sound = .default
        }
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        content.threadIdentifier = "alarm"
        content.userInfo = [
            alarmIDUserInfoKey: alarm.id,
            "alarmTime": alarm.displayTime
        ]
        return content
    }

    private static func removeAlarmNotifications(from center: UNUserNotificationCenter) async {
        let pendingRequests = await pendingNotificationRequests(from: center)
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(alarmIdentifierPrefix) }

        guard !identifiers.isEmpty else { return }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private static func requestAuthorization(from center: UNUserNotificationCenter) async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private static func add(_ request: UNNotificationRequest, to center: UNUserNotificationCenter) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private static func notificationSettings(for center: UNUserNotificationCenter) async -> UNNotificationSettings {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNNotificationSettings, Never>) in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private static func pendingNotificationRequests(from center: UNUserNotificationCenter) async -> [UNNotificationRequest] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private static func bundledSoundName() -> String? {
        if Bundle.main.url(forResource: "alarm_chime", withExtension: "wav") != nil {
            return bundledSoundFilename
        }

        if Bundle.main.url(forResource: "alarm_chime", withExtension: "wav", subdirectory: "Resources") != nil {
            return "Resources/\(bundledSoundFilename)"
        }

        return nil
    }
}
