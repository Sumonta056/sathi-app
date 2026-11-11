import Foundation

package struct BuddyTabReport: Equatable, Sendable {
    package var habit: HabitID
    package var title: String
    package var goalText: String
    package var chart: ReportChart
    package var totalLabel: String
    package var totalText: String
    package var changeText: String
    package var isUp: Bool
    package var facts: [ReportFact]
}

package struct BuddyTabParts: Sendable {
    package var chart: ReportChart
    package var change: RangeChange
    package var streak: Int
}

package struct BuddyTabBuilder: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar) {
        self.calendar = .gregorian(in: calendar.timeZone)
    }

    package func build(
        _ id: HabitID,
        range: StatsRange,
        judge: BuddyDayJudge,
        parts: BuddyTabParts
    ) -> BuddyTabReport {
        let change = parts.change
        let days = range.days.map(\.start)
        let past = days.filter(judge.isPast)
        let total = days.reduce(0) { $0 + judge.total(id, on: $1) }
        let counted = past.filter { judge.isCounted(id, on: $0) }
        let average = counted.isEmpty ? 0 : counted.reduce(0) { $0 + judge.total(id, on: $1) } / Double(counted.count)
        var facts = [ReportFact(
            label: Copywriter.reportsFactGoalDays,
            value: Copywriter.reportsGoalDaysOf(past.filter { judge.isMet(id, on: $0) }.count, days: days.count)
        )]
        if range.kind != .day {
            facts.append(ReportFact(label: Copywriter.reportsFactBestDay, value: bestDay(id, days: past, judge: judge, kind: range.kind)))
        }
        facts.append(ReportFact(label: Copywriter.reportsFactAverage, value: Copywriter.reportsShortAmount(id, average)))
        facts.append(ReportFact(label: Copywriter.reportsFactStreak, value: ReportScreenBuilder.days(parts.streak)))
        return BuddyTabReport(
            habit: id,
            title: Copywriter.reportsChartTitle(id),
            goalText: Copywriter.reportsGoalLine(id, goal: judge.goal(id)),
            chart: parts.chart,
            totalLabel: Copywriter.reportsTotalLabel(range.kind, isCurrent: range.holds(judge.now)),
            totalText: Copywriter.reportsAmount(id, total),
            changeText: Copywriter.rangeChange(change, kind: range.kind) { Copywriter.reportsAmount(id, $0) },
            isUp: { if case .up = change { true } else { false } }(),
            facts: facts
        )
    }

    private func bestDay(_ id: HabitID, days: [Date], judge: BuddyDayJudge, kind: ReportRange) -> String {
        let best = days.max { judge.total(id, on: $0) < judge.total(id, on: $1) }
        guard let best, judge.total(id, on: best) > 0 else { return Copywriter.reportsNoValue }
        let pattern = kind == .week ? "EEE" : "d MMM"
        return Copywriter.rangeDate(best, pattern, calendar.timeZone) + " · " + Copywriter.reportsShortAmount(id, judge.total(id, on: best))
    }
}
