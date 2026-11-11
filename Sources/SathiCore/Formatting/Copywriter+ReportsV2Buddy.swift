import Foundation

extension Copywriter {
    package static let reportsFactGoalDays = "Goal days"
    package static let reportsFactBestDay = "Best day"
    package static let reportsFactAverage = "Daily average"
    package static let reportsFactStreak = "Streak"

    package static func reportsChartTitle(_ id: HabitID) -> String {
        let unit = switch id {
        case .water: "glasses"
        case .reading: "reading minutes"
        case .meditation: "meditation minutes"
        case .gym: "gym minutes"
        }
        return id.buddy + " · " + unit
    }

    package static func reportsGoalLine(_ id: HabitID, goal: Double) -> String {
        let amount = reportsShortAmount(.water, goal)
        let unit = id == .water ? (goal == 1 ? " glass" : " glasses") : " min"
        return "daily goal " + amount + unit
    }

    package static func reportsTotalLabel(_ kind: ReportRange, isCurrent: Bool) -> String {
        switch kind {
        case .day: isCurrent ? "TODAY" : "DAY TOTAL"
        case .week: isCurrent ? "THIS WEEK" : "WEEK TOTAL"
        case .month: isCurrent ? "THIS MONTH" : "MONTH TOTAL"
        }
    }

    package static func reportsGoalDaysOf(_ met: Int, days: Int) -> String {
        "\(met) of \(days)"
    }

    package static func reportsGoalDayCount(_ count: Int) -> String {
        count == 1 ? "1 goal day" : "\(count) goal days"
    }

    package static func reportsBuddyMonthTitle(_ id: HabitID, month: Date, zone: TimeZone) -> String {
        id.buddy + " · " + rangeDate(month, "MMMM", zone)
    }

    package static func reportsBarValue(_ id: HabitID, _ amount: Double, metGoal: Bool) -> String {
        reportsShortAmount(id, amount) + (metGoal ? " \u{2713}" : "")
    }
}
