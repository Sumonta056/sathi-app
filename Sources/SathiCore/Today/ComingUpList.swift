import Foundation

package enum ComingUpKind: Equatable, Sendable {
    case trackerAsk
    case habit(HabitID)
    case quick(UUID)
    case daySummary
}

package struct ComingUpItem: Equatable, Identifiable, Sendable {
    package var kind: ComingUpKind
    package var title: String
    package var time: Date

    package var id: String { "\(kind)-\(time.timeIntervalSince1970)" }

    package init(kind: ComingUpKind, title: String, time: Date) {
        self.kind = kind
        self.title = title
        self.time = time
    }
}

package enum ComingUpList {
    package static func make(items: [ComingUpItem], now: Date, calendar: Calendar) -> [ComingUpItem] {
        let today = items.filter { $0.time > now && calendar.isDate($0.time, inSameDayAs: now) }
        let sorted = today.sorted { ($0.time, $0.title) < ($1.time, $1.title) }
        return Array(sorted.prefix(Limits.comingUpMax))
    }
}
