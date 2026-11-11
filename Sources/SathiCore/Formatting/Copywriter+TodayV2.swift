import Foundation

extension Copywriter {
    package static let todayBreakdownTitle = "Breakdown"
    package static let todayNowMarker = "Now"

    package static func todayLoggedSummary(percent: Int?) -> String {
        guard let percent else { return "logged" }
        return "logged · \(percent)% of tracker hours"
    }

    package static func todayNowAt(_ time: Date, calendar: Calendar) -> String {
        todayNowMarker + " " + trackerClock(time, calendar: calendar)
    }

    package static func todayTimeAndDetail(_ time: Date, detail: String?, calendar: Calendar) -> String {
        let clock = trackerClock(time, calendar: calendar)
        guard let detail, !detail.isEmpty else { return clock }
        return clock + " · " + detail
    }

    package static func todayInMinutes(_ seconds: TimeInterval) -> String {
        if seconds <= 0 { return "now" }
        if seconds >= Timing.hour { return "in " + Fmt.short(seconds) }
        return "in \(Int((seconds / Timing.minute).rounded(.up))) min"
    }

    package static func todayCategoryCount(_ n: Int) -> String {
        n == 1 ? "1 category" : "\(n) categories"
    }
}
