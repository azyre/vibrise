import Foundation

struct Alarm: Identifiable, Equatable, Codable {
    let id: Int
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var repeatDays: [Int]
}

extension Alarm {
    static let dayShortLabels = ["S", "M", "T", "W", "T", "F", "S"]
    static let mockWeekdayMorning = Alarm(
        id: 1,
        isEnabled: true,
        hour: 7,
        minute: 0,
        repeatDays: [1, 2, 3, 4, 5]
    )

    var displayTime: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var sortedRepeatDays: [Int] {
        repeatDays.sorted()
    }

    var displayRepeatDays: String {
        let labels = sortedRepeatDays.compactMap { index in
            Alarm.dayShortLabels.indices.contains(index) ? Alarm.dayShortLabels[index] : nil
        }
        return labels.isEmpty ? "Once" : labels.joined(separator: " ")
    }

    func addingMinutes(_ minutesToAdd: Int) -> String {
        let totalMinutes = (hour * 60 + minute + minutesToAdd) % (24 * 60)
        let nextHour = totalMinutes / 60
        let nextMinute = totalMinutes % 60
        return String(format: "%02d:%02d", nextHour, nextMinute)
    }
}
