import AppIntents

@available(iOS 26.0, *)
struct OpenRingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Buy Me a Coffee"

    static var supportedModes: IntentModes {
        .foreground(.immediate)
    }

    @Parameter(title: "Alarm ID")
    var alarmID: Int

    init() {}

    init(alarmID: Int) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AlarmRingLaunchBridge.requestOpenRing(
                alarmID: alarmID,
                autoPresentDonation: true
            )
        }
        return .result()
    }
}
