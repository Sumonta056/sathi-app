import Foundation

extension Copywriter {
    package static let todayStillOnIt = "Still on it?"
    package static let todayDueNow = "Due now"
    package static let todayPaused = "Paused"
    package static let todayDaySummary = "Day summary"
    package static let todayNothingMore = "Nothing more today."
    package static let todayGlassesUnit = "glasses"
    package static let todayMinutesUnit = "min"
    package static let todayTrackerOff = "Activity tracker is off"

    package static func todayDateLine(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: date).uppercased()
    }

    package static func todayNextAt(_ time: Date, calendar: Calendar) -> String {
        "Next at " + trackerClock(time, calendar: calendar)
    }

    package static func todayGymSession(_ n: Int, of m: Int, at time: Date, calendar: Calendar) -> String {
        "Session \(n) of \(m) at " + trackerClock(time, calendar: calendar)
    }

    package static func todayItemName(_ id: HabitID) -> String {
        "\(id.buddy) · \(id.name.lowercased())"
    }

    package static func todaySnoozed(until time: Date, calendar: Calendar) -> String {
        "Snoozed until " + trackerClock(time, calendar: calendar)
    }
}
