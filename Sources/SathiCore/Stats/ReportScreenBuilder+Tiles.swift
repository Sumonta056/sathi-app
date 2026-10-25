import Foundation

extension ReportScreenBuilder {
    func tile(_ id: HabitID, range: ReportRange, report: HabitReport, isOff: Bool) -> ReportTile {
        let amount = range == .day ? report.total : report.averagePerDay
        return ReportTile(
            habit: id,
            label: id.name.uppercased(),
            value: Self.value(amount, for: id),
            unit: Self.unitName(id) + (range == .day ? " today" : " / day"),
            percent: report.percentOfGoal,
            note: isOff ? "Off" : "\(report.percentOfGoal)% of your daily goal",
            isOff: isOff
        )
    }

    private static func value(_ amount: Double, for id: HabitID) -> String {
        switch id {
        case .water: return String(format: "%.1f", amount)
        case .reading, .meditation: return "\(Int(amount.rounded()))"
        }
    }

    private static func unitName(_ id: HabitID) -> String {
        switch id {
        case .water: return "glasses"
        case .reading, .meditation: return "min"
        }
    }
}
