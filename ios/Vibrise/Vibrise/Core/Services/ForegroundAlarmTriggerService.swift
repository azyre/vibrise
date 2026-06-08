import Foundation

enum ForegroundAlarmTriggerService {
    static func dueOccurrence(
        from alarms: [Alarm],
        now: Date,
        lastTriggeredTriggerKey: String?,
        isSystemAlarmAuthorized: Bool,
        calendar: Calendar = .current
    ) -> ScheduledAlarmOccurrence? {
        guard !isSystemAlarmAuthorized else {
            return nil
        }

        guard let dueOccurrence = AlarmSchedulingService.dueOccurrence(
            from: alarms,
            now: now,
            calendar: calendar
        ) else {
            return nil
        }

        guard dueOccurrence.triggerKey != lastTriggeredTriggerKey else {
            return nil
        }

        return dueOccurrence
    }
}
