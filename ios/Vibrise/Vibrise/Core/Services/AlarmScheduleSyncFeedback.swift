import Foundation

enum AlarmScheduleSyncFeedback {
    static func message(for result: AlarmScheduleSyncService.SyncResult) -> String? {
        switch result {
        case .alarmKitAuthorized:
            return nil
        case .notificationFallback:
            return "Using notification fallback for this alarm"
        case .notificationUnauthorized:
            return "Enable Notifications so alarms can still ring"
        case .failed:
            return "Couldn't sync alarms"
        }
    }
}
