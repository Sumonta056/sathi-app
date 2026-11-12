import Foundation

package enum TodayNow: Equatable, Sendable {
    case running(minutes: Int, text: String, category: String?, since: Date, nextAsk: Date?)
    case idle(nextAsk: Date?)
    case off
}

package enum TodayBuddyStatus: Equatable, Sendable {
    case met
    case dayOff
    case off
    case noReminder
    case dueNow
    case paused
    case snoozed(Date)
    case next(Date)
    case gymSession(Int, of: Int, Date)
}

package struct TodayBuddy: Equatable, Identifiable, Sendable {
    package var habit: HabitID
    package var total: String
    package var goal: Int
    package var unit: String
    package var progress: Double
    package var status: TodayBuddyStatus

    package var id: HabitID { habit }

    package init(habit: HabitID, total: String, goal: Int, unit: String, progress: Double, status: TodayBuddyStatus) {
        self.habit = habit
        self.total = total
        self.goal = goal
        self.unit = unit
        self.progress = progress
        self.status = status
    }
}

package struct TodaySoFar: Equatable, Sendable {
    package var isOn: Bool
    package var hours: DateInterval?
    package var segments: [ActivitySegment]
    package var logged: TimeInterval
    package var categories: [ActivityCategoryTotal]

    package init(isOn: Bool, hours: DateInterval? = nil, segments: [ActivitySegment], logged: TimeInterval, categories: [ActivityCategoryTotal]) {
        self.isOn = isOn
        self.hours = hours
        self.segments = segments
        self.logged = logged
        self.categories = categories
    }

    package static let off = TodaySoFar(isOn: false, hours: nil, segments: [], logged: 0, categories: [])
}

package struct TodayScreen: Equatable, Sendable {
    package var dateLine: String
    package var greeting: String
    package var now: TodayNow
    package var buddies: [TodayBuddy]
    package var sofar: TodaySoFar
    package var comingUp: [ComingUpItem]
    package var at: Date
}
