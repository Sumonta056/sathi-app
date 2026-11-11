import Foundation

extension Copywriter {
    package static let reportsExport = "Export CSV"
    package static let reportsExportFailed = "Could not save the file."
    package static let reportsOff = "Off"
    package static let reportsNoActivities = "No activities in this range."

    package static func reportsBuddyLabel(_ id: HabitID) -> String {
        id.buddy + " · " + id.name.lowercased()
    }

    package static func reportsAmount(_ id: HabitID, _ amount: Double) -> String {
        if id == .water { return Fmt.glasses(amount) }
        let minutes = Int(amount.rounded())
        return minutes <= 0 ? "0m" : Fmt.short(TimeInterval(minutes) * Timing.minute)
    }

    package static func reportsGoalMet(_ met: Int, of days: Int) -> String {
        "goal met \(met) of \(days) days"
    }

    package static func reportsGoalDays(buddies: Int) -> String {
        "Goals met per day of \(buddies) buddies"
    }

    package static func reportsCategoryTitle(_ kind: ReportRange) -> String {
        "Time by category vs " + rangeBefore(kind)
    }

    package static func rangeDelta(_ change: RangeChange, format: (Double) -> String) -> String {
        switch change {
        case let .up(amount): return "+" + format(amount)
        case let .down(amount): return "\u{2212}" + format(amount)
        case .same, .none: return ""
        }
    }

    package static func reportsBarLabel(_ day: Date, kind: ReportRange, calendar: Calendar) -> String {
        switch kind {
        case .day: return "Today"
        case .week: return rangeDate(day, "EEE", calendar.timeZone)
        case .month: return rangeDate(day, "d", calendar.timeZone)
        }
    }
}
