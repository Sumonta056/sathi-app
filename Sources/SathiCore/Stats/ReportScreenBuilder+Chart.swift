import Foundation

extension ReportScreenBuilder {
    func chart(_ range: ReportRange, habit: HabitReport) -> ReportChart {
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

    private func barLabel(_ range: ReportRange, index: Int, start: Date) -> String {
        switch range {
        case .day:
            return Self.hourLabel(index * Limits.reportDayBucketHours)
        case .week:
            return weekdayShort.string(from: start)
        case .month:
            return index % Limits.monthLabelEvery == 0 ? dayNumber.string(from: start) : ""
        }
    }

    static func hourLabel(_ hour: Int) -> String {
        let half = Limits.hoursPerDay / 2
        let clock = hour % half == 0 ? half : hour % half
        return "\(clock)" + (hour < half ? "a" : "p")
    }
}
