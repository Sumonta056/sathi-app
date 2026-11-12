import Foundation

package struct BuddyRangeTotal: Equatable, Identifiable {
    package var habit: HabitID
    package var total: Double
    package var change: RangeChange
    package var daysMet: Int
    package var daysCounted: Int
    package var isOff: Bool

    package var id: HabitID { habit }
}

package struct GoalDayBar: Equatable {
    package var day: Date
    package var met: Int
    package var of: Int
    package var isFuture: Bool
}
