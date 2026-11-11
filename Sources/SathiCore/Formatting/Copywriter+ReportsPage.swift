import Foundation

extension Copywriter {
    package static let reportsExport = "Export CSV"
    package static let reportsExportFailed = "Could not save the file."
    package static let reportsExportEmpty = "Nothing to export in this range."
    package static let reportsNoActivities = "No activities in this range."

    package static func reportsAmount(_ id: HabitID, _ amount: Double) -> String {
        if id == .water { return Fmt.glasses(amount) }
        let minutes = Int(amount.rounded())
        return minutes <= 0 ? "0m" : Fmt.short(TimeInterval(minutes) * Timing.minute)
    }

    package static func rangeDelta(_ change: RangeChange, format: (Double) -> String) -> String {
        switch change {
        case let .up(amount): return "+" + format(amount)
        case let .down(amount): return "\u{2212}" + format(amount)
        case .same, .none: return ""
        }
    }
}
