import Foundation

enum AlarmRingLaunchResolver {
    static func requestForCurrentAlertingAlarm(from alarms: [Alarm]) -> PendingRingLaunchRequest? {
        guard let systemAlarmID = AlarmKitSchedulingService.currentAlertingSystemAlarmID(),
              let alarm = alarms.first(where: { AlarmKitSchedulingService.systemAlarmID(for: $0.id) == systemAlarmID }) else {
            return nil
        }

        return PendingRingLaunchRequest(alarmID: alarm.id, autoPresentDonation: false)
    }

    static func requestForCurrentAlertingAlarm(
        using localDataStore: LocalDataStore = UserDefaultsLocalDataStore()
    ) -> PendingRingLaunchRequest? {
        requestForCurrentAlertingAlarm(from: localDataStore.loadAlarms())
    }
}
