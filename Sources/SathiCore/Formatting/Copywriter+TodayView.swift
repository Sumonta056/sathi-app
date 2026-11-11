import Foundation

extension Copywriter {
    package static let todayQuickReminder = "Quick reminder"
    package static let todayNowLabel = "NOW"
    package static let todaySwitch = "Switch"
    package static let todayStop = "Stop"
    package static let todayLogActivity = "Log activity"
    package static let todayTurnOn = "Turn on"
    package static let todayGoalMet = "✓ Goal met"
    package static let todayBreatheNow = "Breathe now"
    package static let todaySoFarTitle = "Today so far"
    package static let todaySoFarOffHint = "Turn on the activity tracker to see your day."
    package static let todayComingUpTitle = "Coming up"
    package static let todayOff = "Off"
    package static let todayDayOff = "Day off"
    package static let todayNoReminder = "No reminder"

    package static func todayNowMinutes(_ minutes: Int) -> String {
        "\(minutes)m"
    }

    package static func todayNowDetail(category: String?, since: Date, nextAsk: Date?, calendar: Calendar) -> String {
        var parts = [category, "since " + trackerClock(since, calendar: calendar)].compactMap { $0 }
        if let nextAsk { parts.append(todayStillOnIt + " at " + trackerClock(nextAsk, calendar: calendar)) }
        return parts.joined(separator: " · ")
    }

    package static func todayIdleDetail(nextAsk: Date, calendar: Calendar) -> String {
        "Next ask " + trackerClock(nextAsk, calendar: calendar)
    }

    package static func todayGoalLine(goal: Int, unit: String) -> String {
        " / \(goal) \(unit)"
    }
}
