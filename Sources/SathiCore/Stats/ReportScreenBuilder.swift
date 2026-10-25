import Foundation

package struct ReportScreenBuilder {
    let calendar: Calendar
    let monthName: DateFormatter
    let weekdayShort: DateFormatter
    let weekdayLong: DateFormatter
    let dayNumber: DateFormatter
    let dayMonth: DateFormatter
    let fullDay: DateFormatter
    let monthYear: DateFormatter

    package init(calendar: Calendar) {
        let gregorian = Calendar.gregorian(in: calendar.timeZone)
        self.calendar = gregorian
        monthName = Self.formatter("MMMM", gregorian)
        weekdayShort = Self.formatter("EEE", gregorian)
        weekdayLong = Self.formatter("EEEE", gregorian)
        dayNumber = Self.formatter("d", gregorian)
        dayMonth = Self.formatter("d MMMM", gregorian)
        fullDay = Self.formatter("EEEE, d MMMM", gregorian)
        monthYear = Self.formatter("MMMM yyyy", gregorian)
    }

    package func build(_ input: ReportScreenInput) -> ReportScreen {
        let range = input.range
        let report = input.report
        let habit = Self.resolve(input.selected, enabled: input.enabled)
        let selectedReport = Self.habitReport(habit, in: report)
        return ReportScreen(
            range: range,
            selected: habit,
            headline: headline(range, report: report, enabled: input.enabled),
            subline: subline(range, interval: report.interval),
            tiles: HabitID.allCases.map {
                tile($0, range: range, report: Self.habitReport($0, in: report), isOff: !input.enabled.contains($0))
            },
            chart: chart(range, habit: selectedReport),
            calendar: streakMonth(Self.habitReport(habit, in: input.month), streak: input.streak, now: input.now),
            facts: facts(range, habit: selectedReport, longest: input.longest)
        )
    }

    static func resolve(_ selected: HabitID, enabled: Set<HabitID>) -> HabitID {
        if enabled.contains(selected) { return selected }
        return HabitID.allCases.first { enabled.contains($0) } ?? .water
    }

    static func habitReport(_ id: HabitID, in report: Report) -> HabitReport {
        report.habits.first { $0.habit == id } ?? HabitReport(
            habit: id,
            goal: 0,
            buckets: [],
            total: 0,
            averagePerDay: 0,
            percentOfGoal: 0,
            daysMet: 0,
            bestDay: nil,
            snoozes: 0
        )
    }

    static func days(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private static func formatter(_ format: String, _ calendar: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateFormat = format
        return f
    }
}
