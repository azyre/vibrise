import Foundation

extension Notification.Name {
    static let vibriseOpenRingRequested = Notification.Name("vibrise.open-ring-requested")
}

struct PendingRingLaunchRequest {
    let alarmID: Int
    let autoPresentDonation: Bool

    init(alarmID: Int, autoPresentDonation: Bool) {
        self.alarmID = alarmID
        self.autoPresentDonation = autoPresentDonation
    }

    init?(userInfo: [AnyHashable: Any]?) {
        guard let alarmID = userInfo?[AlarmNotificationService.alarmIDUserInfoKey] as? Int else {
            return nil
        }

        self.init(
            alarmID: alarmID,
            autoPresentDonation: userInfo?[AlarmRingLaunchBridge.autoPresentDonationUserInfoKey] as? Bool ?? false
        )
    }
}

enum AlarmRingLaunchBridge {
    private static let pendingAlarmIDKey = "vibrise.pending-ring-alarm-id"
    private static let pendingAutoPresentDonationKey = "vibrise.pending-ring-auto-present-donation"
    static let autoPresentDonationUserInfoKey = "autoPresentDonation"

    static func requestOpenRing(alarmID: Int, autoPresentDonation: Bool = false) {
        UserDefaults.standard.set(alarmID, forKey: pendingAlarmIDKey)
        UserDefaults.standard.set(autoPresentDonation, forKey: pendingAutoPresentDonationKey)
        NotificationCenter.default.post(
            name: .vibriseOpenRingRequested,
            object: nil,
            userInfo: [
                AlarmNotificationService.alarmIDUserInfoKey: alarmID,
                autoPresentDonationUserInfoKey: autoPresentDonation
            ]
        )
    }

    static func consumePendingRequest() -> PendingRingLaunchRequest? {
        guard let alarmID = pendingAlarmID() else {
            return nil
        }

        let request = PendingRingLaunchRequest(
            alarmID: alarmID,
            autoPresentDonation: pendingAutoPresentDonation()
        )
        clearPendingRequest(alarmID)
        return request
    }

    static func clearPendingRequest(_ alarmID: Int? = nil) {
        guard let storedAlarmID = pendingAlarmID() else {
            return
        }

        guard alarmID == nil || storedAlarmID == alarmID else {
            return
        }

        UserDefaults.standard.removeObject(forKey: pendingAlarmIDKey)
        UserDefaults.standard.removeObject(forKey: pendingAutoPresentDonationKey)
    }

    private static func pendingAlarmID() -> Int? {
        if let alarmID = UserDefaults.standard.object(forKey: pendingAlarmIDKey) as? Int {
            return alarmID
        }

        if let alarmIDString = UserDefaults.standard.string(forKey: pendingAlarmIDKey) {
            return Int(alarmIDString)
        }

        return nil
    }

    private static func pendingAutoPresentDonation() -> Bool {
        UserDefaults.standard.bool(forKey: pendingAutoPresentDonationKey)
    }
}
