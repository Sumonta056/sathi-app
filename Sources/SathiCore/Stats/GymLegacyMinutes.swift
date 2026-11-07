import Foundation

package enum GymLegacyMinutes {
    package static func apply(_ events: [HistoryEvent], since: Date?) -> [HistoryEvent] {
        guard let since else { return events }
        return events.map { e in
            guard e.habit == .gym, e.kind == .done, e.date < since else { return e }
            var old = e
            old.amount = Double(Limits.gymLegacyDoneMinutes)
            return old
        }
    }
}
