import Combine
import Foundation

@MainActor
final class AlarmRingLaunchCoordinator {
    private let notificationCenter: NotificationCenter
    private var cancellable: AnyCancellable?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func start(onRequest: @escaping (PendingRingLaunchRequest) -> Void) {
        cancellable = notificationCenter.publisher(for: .vibriseOpenRingRequested)
            .compactMap { PendingRingLaunchRequest(userInfo: $0.userInfo) }
            .receive(on: RunLoop.main)
            .sink { request in
                AlarmRingLaunchBridge.clearPendingRequest(request.alarmID)
                onRequest(request)
            }
    }

    func consumePendingRequestIfNeeded() -> PendingRingLaunchRequest? {
        AlarmRingLaunchBridge.consumePendingRequest()
    }
}
