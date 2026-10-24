import Foundation

package enum Level: Equatable, Sendable {
    case nudge, persist
}

package enum Phase: Equatable, Sendable {
    case idle
    case bubble(HabitID, Level)
    case lock(HabitID)
    case session(HabitID)
    case celebrate
}

package struct HabitState: Equatable, Sendable {
    package var nextDue: Date
    package var snoozes = 0
    package var snoozedUntil: Date?

    package init(nextDue: Date) {
        self.nextDue = nextDue
    }
}

package struct Copy: Equatable, Sendable {
    package var title = ""
    package var body = ""

    package init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
    }
}

package struct Celebration: Equatable, Sendable {
    package var id: HabitID = .water
    package var amount: Double = 1
    package var title = ""

    package init(id: HabitID = .water, amount: Double = 1, title: String = "") {
        self.id = id
        self.amount = amount
        self.title = title
    }
}
