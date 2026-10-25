import Foundation

package struct ReportScreen: Equatable, Sendable {
    package var range: ReportRange
    package var selected: HabitID
    package var headline: String
    package var subline: String
    package var tiles: [ReportTile]
    package var chart: ReportChart
    package var calendar: StreakMonth
    package var facts: [ReportFact]
}

package struct ReportTile: Equatable, Sendable, Identifiable {
    package var habit: HabitID
    package var id: HabitID { habit }
    package var label: String
    package var value: String
    package var unit: String
    package var percent: Int
    package var note: String
    package var isOff: Bool
}

package struct ReportChart: Equatable, Sendable {
    package var title: String
    package var bars: [ReportBar]
    package var goal: Double?
}

package struct ReportBar: Equatable, Sendable, Identifiable {
    package var id: Int
    package var label: String
    package var value: Double
    package var metGoal: Bool
}

package struct StreakMonth: Equatable, Sendable {
    package var title: String
    package var streakText: String
    package var leadingBlanks: Int
    package var cells: [StreakCell]
}

package struct StreakCell: Equatable, Sendable, Identifiable {
    package var day: Int
    package var id: Int { day }
    package var level: Int
    package var isToday: Bool
    package var isFuture: Bool
}

package struct ReportFact: Equatable, Sendable, Identifiable {
    package var label: String
    package var id: String { label }
    package var value: String
}
