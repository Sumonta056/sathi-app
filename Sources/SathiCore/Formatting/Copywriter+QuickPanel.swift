import Foundation

extension Copywriter {
    package static let quickPanelTitle = "Sathi"
    package static let quickPanelSwitch = "Switch"
    package static let quickPanelOpen = "Open Sathi"
    package static let quickPanelReports = "Reports"
    package static let quickPanelSettings = "Settings"
    package static let quickPanelQuit = "Quit"
    package static let quickPanelGoalMet = "✓ Goal met"
    package static let quickPanelOff = "Off"
    package static let quickPanelDayOff = "Day off"
    package static let quickPanelPlusGlass = "+1 glass"

    package static func quickPanelClock(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE HH:mm"
        return f.string(from: date)
    }

    package static func quickPanelNow(_ seconds: TimeInterval) -> String {
        "NOW · " + trackerDuration(seconds)
    }

    package static func quickPanelStatus(_ buddy: TodayBuddy, calendar: Calendar) -> String {
        switch buddy.status {
        case .met: return quickPanelGoalMet
        case .off: return quickPanelOff
        case .dayOff: return quickPanelDayOff
        case .dueNow: return todayDueNow
        case .paused: return todayPaused
        case let .snoozed(time): return todaySnoozed(until: time, calendar: calendar)
        case .noReminder: return quickPanelProgress(buddy)
        case let .next(time), let .gymSession(_, _, time):
            let started = buddy.habit == .water || buddy.progress > 0
            return started ? quickPanelProgress(buddy) : trackerClock(time, calendar: calendar)
        }
    }

    private static func quickPanelProgress(_ buddy: TodayBuddy) -> String {
        let text = "\(buddy.total) / \(buddy.goal)"
        return buddy.unit == todayMinutesUnit ? text + " " + buddy.unit : text
    }
}
