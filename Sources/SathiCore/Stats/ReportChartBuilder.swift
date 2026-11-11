import Foundation

package struct ReportChartBuilder {
    let calendar: Calendar
    let weekdayShort: DateFormatter
    let dayNumber: DateFormatter

    package init(calendar: Calendar) {
        let gregorian = Calendar.gregorian(in: calendar.timeZone)
        self.calendar = gregorian
        weekdayShort = Self.formatter("EEE", gregorian)
        dayNumber = Self.formatter("d", gregorian)
    }

    package func chart(_ range: ReportRange, habit: HabitReport) -> ReportChart {
        let goal: Double? = range == .day || habit.goal <= 0 ? nil : habit.goal
        let bars = habit.buckets.enumerated().map { index, bucket in
            ReportBar(
                id: index,
                label: barLabel(range, index: index, start: bucket.start),
                value: bucket.total,
                metGoal: range == .day ? bucket.total > 0 : habit.goal > 0 && bucket.total >= habit.goal
            )
        }
        return ReportChart(title: "\(habit.habit.name) · \(Self.rangeWord(range).lowercased())", bars: bars, goal: goal)
    }

    package static func habitReport(_ id: HabitID, in report: Report) -> HabitReport {
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

    static func rangeWord(_ range: ReportRange) -> String {
        switch range {
        case .day: "Today"
        case .week: "This week"
        case .month: "This month"
        }
    }

    static func hourLabel(_ hour: Int) -> String {
        let half = Limits.hoursPerDay / 2
        let clock = hour % half == 0 ? half : hour % half
        return "\(clock)" + (hour < half ? "a" : "p")
    }

    private func barLabel(_ range: ReportRange, index: Int, start: Date) -> String {
        switch range {
        case .day: Self.hourLabel(index * Limits.reportDayBucketHours)
        case .week: weekdayShort.string(from: start)
        case .month: index % Limits.monthLabelEvery == 0 ? dayNumber.string(from: start) : ""
        }
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
