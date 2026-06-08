import Foundation

struct RingSession: Identifiable, Equatable {
    let alarm: Alarm
    let song: Song

    var id: String {
        "\(alarm.id)-\(song.id)"
    }
}

struct PendingSnoozeSession: Identifiable, Equatable {
    let alarm: Alarm
    let song: Song
    let triggerDate: Date

    var id: String {
        "\(alarm.id)-\(Int(triggerDate.timeIntervalSince1970))"
    }

    var triggerKey: String {
        "snooze-\(alarm.id)-\(Int(triggerDate.timeIntervalSince1970 / 60))"
    }
}
