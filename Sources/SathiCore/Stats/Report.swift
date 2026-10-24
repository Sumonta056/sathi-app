import Foundation

package enum ReportRange: String, CaseIterable, Sendable {
    case day, week, month
}

package struct ReportBucket: Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var total: Double

    package init(start: Date, end: Date, total: Double) {
        self.start = start
        self.end = end
        self.total = total
    }
}

package struct HabitReport: Equatable, Sendable {
    package var habit: HabitID
    package var goal: Double
    package var buckets: [ReportBucket]
    package var total: Double
    package var averagePerDay: Double
    package var percentOfGoal: Int
    package var daysMet: Int
    package var bestDay: Date?
    package var snoozes: Int
}

package struct Report: Equatable, Sendable {
    package var range: ReportRange
    package var interval: DateInterval
    package var habits: [HabitReport]
}
