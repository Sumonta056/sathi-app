import Foundation

extension Copywriter {
    package static let todayBreakdownTitle = "Breakdown"
    package static let todayNowMarker = "Now"

    package static func todayLoggedSummary(percent: Int?) -> String {
        guard let percent else { return "logged" }
        return "logged · \(percent)% of tracker hours"
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
