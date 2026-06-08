import UIKit
import UserNotifications
import WidgetKit

final class AlarmAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let request = notificationLaunchRequest(from: response) else {
            completionHandler()
            return
        }

        routeToRing(request)
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeLiveActivity else {
            return false
        }

        return handleLiveActivityContinuation()
    }

    private func notificationLaunchRequest(from response: UNNotificationResponse) -> PendingRingLaunchRequest? {
        guard let alarmID = AlarmNotificationService.alarmID(from: response.notification.request.content.userInfo) else {
            return nil
        }

        return PendingRingLaunchRequest(alarmID: alarmID, autoPresentDonation: false)
    }

    private func handleLiveActivityContinuation() -> Bool {
        if let request = AlarmRingLaunchBridge.consumePendingRequest() {
            routeToRing(request)
            return true
        }

        if let request = AlarmRingLaunchResolver.requestForCurrentAlertingAlarm() {
            routeToRing(request)
            return true
        }

        return false
    }

    private func routeToRing(_ request: PendingRingLaunchRequest) {
        AlarmRingLaunchBridge.requestOpenRing(
            alarmID: request.alarmID,
            autoPresentDonation: request.autoPresentDonation
        )
    }
}
