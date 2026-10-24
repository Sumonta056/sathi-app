import Foundation

package enum EventKind: String, Codable, Sendable {
    case done, snooze, skip
}

package struct HistoryEvent: Codable, Equatable, Sendable {
    package var date: Date
    package var habit: HabitID
    package var kind: EventKind
    package var amount: Double

    package init(date: Date, habit: HabitID, kind: EventKind, amount: Double = 0) {
        self.date = date.wholeSecond
        self.habit = habit
        self.kind = kind
        self.amount = amount
    }

    package static func done(_ habit: HabitID, _ amount: Double, at date: Date) -> HistoryEvent {
        HistoryEvent(date: date, habit: habit, kind: .done, amount: amount)
    }

    package static func snooze(_ habit: HabitID, at date: Date) -> HistoryEvent {
        HistoryEvent(date: date, habit: habit, kind: .snooze)
    }

    package static func skip(_ habit: HabitID, at date: Date) -> HistoryEvent {
        HistoryEvent(date: date, habit: habit, kind: .skip)
    }
}

extension HistoryEvent {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(Date.self, forKey: .date).wholeSecond
        habit = try c.decode(HabitID.self, forKey: .habit)
        kind = try c.decode(EventKind.self, forKey: .kind)
        amount = try c.value(.amount, or: 0)
    }
}
