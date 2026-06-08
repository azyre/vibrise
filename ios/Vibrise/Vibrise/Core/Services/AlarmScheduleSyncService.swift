import Foundation

enum AlarmScheduleSyncService {
    enum SyncResult {
        case alarmKitAuthorized
        case notificationFallback
        case notificationUnauthorized
        case failed
    }

    static func sync(
        alarms: [Alarm],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async -> SyncResult {
        if #available(iOS 26.0, *) {
            switch await AlarmKitSchedulingService.syncAlarms(
                for: alarms,
                now: now,
                calendar: calendar
            ) {
            case .authorized:
                await AlarmNotificationService.clearSyncedNotifications()
                return .alarmKitAuthorized
            case .failed:
                return await syncNotificationFallback(
                    alarms: alarms,
                    now: now,
                    calendar: calendar
                )
            case .unauthorized:
                return await syncNotificationFallback(
                    alarms: alarms,
                    now: now,
                    calendar: calendar
                )
            }
        } else {
            return await syncNotificationFallback(
                alarms: alarms,
                now: now,
                calendar: calendar
            )
        }
    }

    private static func syncNotificationFallback(
        alarms: [Alarm],
        now: Date,
        calendar: Calendar
    ) async -> SyncResult {
        switch await AlarmNotificationService.syncNotifications(
            for: alarms,
            now: now,
            calendar: calendar
        ) {
        case .scheduled:
            return .notificationFallback
        case .unauthorized:
            return .notificationUnauthorized
        case .failed:
            return .failed
        }
    }
}
