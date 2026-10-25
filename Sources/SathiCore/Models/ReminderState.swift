import Foundation

package enum Level: Equatable, Sendable {
    case nudge, persist
}

package enum Phase: Equatable, Sendable {
    case idle
    case bubble(Level)
    case lock
    case session
}

package struct Session: Equatable, Sendable {
    package var start: Date
    package var end: Date
    package var fromReminder: Bool

    package init(start: Date, end: Date, fromReminder: Bool = false) {
        self.start = start
        self.end = end
        self.fromReminder = fromReminder
    }
}

package enum Activity: Equatable, Sendable {
    case bubble(Level, copy: Copy, ignoreDeadline: Date)
    case lock
    case session(Session)

    package var phase: Phase {
        switch self {
        case let .bubble(level, _, _): return .bubble(level)
        case .lock: return .lock
        case .session: return .session
        }
    }
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
