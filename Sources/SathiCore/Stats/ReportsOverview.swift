import Foundation

package struct BuddyScore: Equatable, Sendable, Identifiable {
    package var habit: HabitID
    package var met: Int
    package var days: Int
    package var counted: Int
    package var isOff: Bool

    package var id: HabitID { habit }
}

package struct ReportsScore: Equatable, Sendable {
    package var met: Int
    package var possible: Int
    package var label: String
    package var headline: String
    package var changeText: String
    package var isUp: Bool
}

package struct DayColumn: Equatable, Sendable, Identifiable {
    package var date: Date
    package var label: String
    package var isToday: Bool
    package var isFuture: Bool

    package var id: Date { date }
}

package struct BuddyDayCell: Equatable, Sendable, Identifiable {
    package var day: Date
    package var text: String
    package var state: BuddyDayState

    package var id: Date { day }
}

package struct BuddyDayRow: Equatable, Sendable, Identifiable {
    package var habit: HabitID
    package var cells: [BuddyDayCell]

    package var id: HabitID { habit }
}

package struct ReportsOverview: Equatable, Sendable {
    package var scores: [BuddyScore]
    package var score: ReportsScore
    package var columns: [DayColumn]
    package var rows: [BuddyDayRow]
    package var streak: Int
}

package struct BuddyDot: Equatable, Sendable, Identifiable {
    package var habit: HabitID
    package var isMet: Bool

    package var id: HabitID { habit }
}

package struct OverviewDay: Equatable, Sendable, Identifiable {
    package var day: Int
    package var dots: [BuddyDot]
    package var isStreakDay: Bool
    package var isToday: Bool
    package var isFuture: Bool

    package var id: Int { day }
}

package struct OverviewMonth: Equatable, Sendable {
    package var title: String
    package var streakText: String
    package var leadingBlanks: Int
    package var days: [OverviewDay]
    package var canGoForward: Bool
}

package struct BuddyMonthCell: Equatable, Sendable, Identifiable {
    package var day: Int
    package var state: BuddyDayState
    package var isToday: Bool

    package var id: Int { day }
}

package struct BuddyMonth: Equatable, Sendable {
    package var habit: HabitID
    package var title: String
    package var goalDaysText: String
    package var leadingBlanks: Int
    package var cells: [BuddyMonthCell]
    package var canGoForward: Bool
}
