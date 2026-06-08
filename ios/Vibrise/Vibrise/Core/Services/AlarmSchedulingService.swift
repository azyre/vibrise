import Foundation

struct ScheduledAlarmOccurrence: Equatable {
    let alarm: Alarm
    let triggerDate: Date

    var triggerKey: String {
        "\(alarm.id)-\(Int(triggerDate.timeIntervalSince1970 / 60))"
    }
}

enum AlarmSchedulingService {
    static func nextScheduledOccurrence(from alarms: [Alarm], now: Date = Date(), calendar: Calendar = .current) -> ScheduledAlarmOccurrence? {
        alarms
            .filter(\.isEnabled)
            .compactMap { alarm in
                nextOccurrence(for: alarm, now: now, calendar: calendar).map {
                    ScheduledAlarmOccurrence(alarm: alarm, triggerDate: $0)
                }
            }
            .min { lhs, rhs in
                lhs.triggerDate < rhs.triggerDate
            }
    }

    static func dueOccurrence(from alarms: [Alarm], now: Date = Date(), calendar: Calendar = .current) -> ScheduledAlarmOccurrence? {
        let startOfCurrentMinute = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let endOfCurrentMinute = calendar.date(byAdding: .minute, value: 1, to: startOfCurrentMinute) ?? now

        return alarms
            .filter(\.isEnabled)
            .compactMap { alarm in
                occurrenceInCurrentMinute(
                    for: alarm,
                    startOfCurrentMinute: startOfCurrentMinute,
                    endOfCurrentMinute: endOfCurrentMinute,
                    calendar: calendar
                )
            }
            .min { lhs, rhs in
                lhs.triggerDate < rhs.triggerDate
            }
    }

    static func nextOccurrence(for alarm: Alarm, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        let nowComponents = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute], from: now)

        if alarm.repeatDays.isEmpty {
            return nextOneShotOccurrence(for: alarm, now: now, calendar: calendar, components: nowComponents)
        }

        for dayOffset in 0..<7 {
            guard let candidateDay = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let candidateWeekday = calendar.dateComponents([.weekday], from: candidateDay).weekday else {
                continue
            }

            let repeatDayIndex = candidateWeekday - 1
            guard alarm.repeatDays.contains(repeatDayIndex),
                  let candidateDate = candidateDate(for: alarm, on: candidateDay, calendar: calendar) else {
                continue
            }

            if candidateDate >= now {
                return candidateDate
            }
        }

        return nil
    }

    private static func nextOneShotOccurrence(
        for alarm: Alarm,
        now: Date,
        calendar: Calendar,
        components: DateComponents
    ) -> Date? {
        guard let today = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day)),
              let todayCandidate = candidateDate(for: alarm, on: today, calendar: calendar) else {
            return nil
        }

        if todayCandidate >= now {
            return todayCandidate
        }

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }

        return candidateDate(for: alarm, on: tomorrow, calendar: calendar)
    }

    private static func candidateDate(for alarm: Alarm, on baseDate: Date, calendar: Calendar) -> Date? {
        let baseComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        return calendar.date(from: DateComponents(
            year: baseComponents.year,
            month: baseComponents.month,
            day: baseComponents.day,
            hour: alarm.hour,
            minute: alarm.minute
        ))
    }

    private static func occurrenceInCurrentMinute(
        for alarm: Alarm,
        startOfCurrentMinute: Date,
        endOfCurrentMinute: Date,
        calendar: Calendar
    ) -> ScheduledAlarmOccurrence? {
        guard let candidateDate = candidateDate(for: alarm, on: startOfCurrentMinute, calendar: calendar) else {
            return nil
        }

        if !alarm.repeatDays.isEmpty {
            let weekday = (calendar.dateComponents([.weekday], from: startOfCurrentMinute).weekday ?? 1) - 1
            guard alarm.repeatDays.contains(weekday) else {
                return nil
            }
        }

        guard candidateDate >= startOfCurrentMinute && candidateDate < endOfCurrentMinute else {
            return nil
        }

        return ScheduledAlarmOccurrence(alarm: alarm, triggerDate: candidateDate)
    }
}
