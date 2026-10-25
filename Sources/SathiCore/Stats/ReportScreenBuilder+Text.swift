import Foundation

extension ReportScreenBuilder {
    static func rangeWord(_ range: ReportRange) -> String {
        switch range {
        case .day: return "Today"
        case .week: return "This week"
        case .month: return "This month"
        }
    }

    func headline(_ range: ReportRange, report: Report, enabled: Set<HabitID>) -> String {
        let word = Self.rangeWord(range)
        let percents = report.habits.filter { enabled.contains($0.habit) }.map(\.percentOfGoal)
        guard !percents.isEmpty else { return "\(word), your buddies are resting" }
        let average = percents.reduce(0, +) / percents.count
        if average >= Limits.headlineGreatPercent { return "\(word), you did great" }
        if average >= Limits.headlineGoodPercent { return "\(word), nice progress" }
        return "\(word), every bit counts"
    }

    func subline(_ range: ReportRange, interval: DateInterval) -> String {
        switch range {
        case .day:
            return fullDay.string(from: interval.start)
        case .week:
            let last = calendar.stepDays(-1, from: interval.end)
            let sameMonth = calendar.isDate(interval.start, equalTo: last, toGranularity: .month)
            let first = (sameMonth ? dayNumber : dayMonth).string(from: interval.start)
            return first + " \u{2013} " + dayMonth.string(from: last)
        case .month:
            return monthYear.string(from: interval.start)
        }
    }

    func facts(_ range: ReportRange, habit: HabitReport, longest: Int) -> [ReportFact] {
        var facts: [ReportFact] = []
        if let format = bestDayFormat(range) {
            let value = habit.bestDay.map { format.string(from: $0) } ?? "\u{2014}"
            facts.append(ReportFact(label: "Best day", value: value))
        }
        facts.append(ReportFact(label: "Snoozes \(Self.rangeWord(range).lowercased())", value: "\(habit.snoozes)"))
        facts.append(ReportFact(label: "Longest streak", value: Self.days(longest)))
        return facts
    }

    private func bestDayFormat(_ range: ReportRange) -> DateFormatter? {
        switch range {
        case .day: return nil
        case .week: return weekdayLong
        case .month: return dayMonth
        }
    }
}
