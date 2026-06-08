import ActivityKit
import AlarmKit
import Foundation
import SwiftUI

struct VibriseAlarmMetadata: AlarmMetadata {
    let alarmID: Int
}

enum AlarmKitSchedulingService {
    enum SyncResult {
        case authorized
        case unauthorized
        case failed
    }

    static var isSystemAlarmAuthorized: Bool {
        if #available(iOS 26.0, *) {
            return AlarmManager.shared.authorizationState == .authorized
        }

        return false
    }

    static func syncAlarms(
        for alarms: [Alarm],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async -> SyncResult {
        guard #available(iOS 26.0, *) else {
            return .unauthorized
        }

        let manager = AlarmManager.shared
        let authorizationState: AlarmManager.AuthorizationState

        switch manager.authorizationState {
        case .authorized:
            authorizationState = .authorized
        case .denied:
            authorizationState = .denied
        case .notDetermined:
            authorizationState = (try? await manager.requestAuthorization()) ?? .denied
        @unknown default:
            authorizationState = .denied
        }

        guard authorizationState == .authorized else {
            try? cancelAllScheduledAlarms(using: manager)
            return .unauthorized
        }

        do {
            try cancelAllScheduledAlarms(using: manager)

            let enabledAlarms = alarms.filter(\.isEnabled)
            let expectedAlarmIDs = Set(enabledAlarms.map { systemAlarmID(for: $0.id) })

            for alarm in enabledAlarms {
                guard let configuration = configuration(for: alarm, now: now, calendar: calendar) else {
                    continue
                }

                _ = try await manager.schedule(
                    id: systemAlarmID(for: alarm.id),
                    configuration: configuration
                )
            }

            guard try verifyScheduledAlarms(expectedAlarmIDs, using: manager) else {
                return .failed
            }

            return .authorized
        } catch {
            return .failed
        }
    }

    @available(iOS 26.0, *)
    private static func configuration(
        for alarm: Alarm,
        now: Date,
        calendar: Calendar
    ) -> AlarmManager.AlarmConfiguration<VibriseAlarmMetadata>? {
        guard let schedule = schedule(for: alarm, now: now, calendar: calendar) else {
            return nil
        }

        let presentation = AlarmPresentation(
            alert: .init(
                title: "Wake up",
                secondaryButton: AlarmButton(
                    text: "Buy me a coffee",
                    textColor: .white,
                    systemImageName: "cup.and.saucer"
                ),
                secondaryButtonBehavior: .custom
            )
        )
        let attributes = AlarmAttributes<VibriseAlarmMetadata>(
            presentation: presentation,
            metadata: VibriseAlarmMetadata(alarmID: alarm.id),
            tintColor: .orange
        )

        return .alarm(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: OpenRingIntent(alarmID: alarm.id),
            sound: .default
        )
    }

    @available(iOS 26.0, *)
    private static func schedule(for alarm: Alarm, now: Date, calendar: Calendar) -> AlarmKit.Alarm.Schedule? {
        if alarm.repeatDays.isEmpty {
            guard let triggerDate = AlarmSchedulingService.nextOccurrence(for: alarm, now: now, calendar: calendar) else {
                return nil
            }
            return .fixed(triggerDate)
        }

        let weekdays = alarm.sortedRepeatDays.compactMap(localeWeekday(for:))
        guard !weekdays.isEmpty else {
            return nil
        }

        return .relative(
            .init(
                time: .init(hour: alarm.hour, minute: alarm.minute),
                repeats: .weekly(weekdays)
            )
        )
    }

    @available(iOS 26.0, *)
    nonisolated private static func localeWeekday(for repeatDay: Int) -> Locale.Weekday? {
        switch repeatDay {
        case 0:
            return .sunday
        case 1:
            return .monday
        case 2:
            return .tuesday
        case 3:
            return .wednesday
        case 4:
            return .thursday
        case 5:
            return .friday
        case 6:
            return .saturday
        default:
            return nil
        }
    }

    @available(iOS 26.0, *)
    private static func cancelAllScheduledAlarms(using manager: AlarmManager) throws {
        let existingAlarms = try manager.alarms
        for alarm in existingAlarms {
            try manager.cancel(id: alarm.id)
        }
    }

    @available(iOS 26.0, *)
    private static func verifyScheduledAlarms(_ expectedAlarmIDs: Set<UUID>, using manager: AlarmManager) throws -> Bool {
        guard !expectedAlarmIDs.isEmpty else {
            return true
        }

        let actualAlarmIDs = Set(try manager.alarms.map(\.id))
        return expectedAlarmIDs.isSubset(of: actualAlarmIDs)
    }

    static func systemAlarmID(for alarmID: Int) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let seed = Array("vibrise-alarm-\(alarmID)".utf8)

        for (index, byte) in seed.enumerated() {
            bytes[index % 16] = bytes[index % 16] &+ byte &+ UInt8(index & 0xFF)
        }

        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func currentAlertingSystemAlarmID() -> UUID? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        guard let systemAlarm = try? AlarmManager.shared.alarms.first(where: { $0.state == .alerting }) else {
            return nil
        }

        return systemAlarm.id
    }
}
