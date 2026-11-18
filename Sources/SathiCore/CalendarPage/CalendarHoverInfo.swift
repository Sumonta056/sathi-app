import Foundation

package enum CalendarHoverKind: Equatable, Sendable {
    case event
    case activity
    case todo
    case away
}

package enum CalendarHoverAction: Equatable, Sendable, CaseIterable {
    case startAsActivity
    case edit
    case openInCalendar
    case delete
    case markDone
    case openInReminders
    case editAway
}

package struct CalendarHoverChild: Equatable, Identifiable, Sendable {
    package var id: String
    package var title: String
    package var time: String

    package init(id: String, title: String, time: String) {
        self.id = id
        self.title = title
        self.time = time
    }
}

package struct CalendarHoverLookup: Equatable, Sendable {
    package var calendarNames: [String: String]
    package var readOnlyEventIDs: Set<String>
    package var todoListNames: [String: String]
    package var now: Date?
    package var trackerOn: Bool

    package init(
        calendarNames: [String: String] = [:],
        readOnlyEventIDs: Set<String> = [],
        todoListNames: [String: String] = [:],
        now: Date? = nil,
        trackerOn: Bool = false
    ) {
        self.calendarNames = calendarNames
        self.readOnlyEventIDs = readOnlyEventIDs
        self.todoListNames = todoListNames
        self.now = now
        self.trackerOn = trackerOn
    }
}

package struct CalendarHoverInfo: Equatable, Sendable {
    package var id: String
    package var kind: CalendarHoverKind
    package var kindLabel: String
    package var title: String
    package var time: String
    package var length: String?
    package var meta: String?
    package var doneDuringTitle: String?
    package var doneDuring: [CalendarHoverChild] = []
    package var alsoHereTitle: String?
    package var alsoHere: [CalendarHoverChild] = []
    package var actions: [CalendarHoverAction]

    package static func make(
        _ laid: CalendarLaidBlock, among day: [CalendarLaidBlock], lookup: CalendarHoverLookup, calendar: Calendar
    ) -> CalendarHoverInfo {
        let b = laid.block
        let r = laid.rounded
        let kind = kind(of: b)
        let point = r.duration == 0
        let done = kind == .event ? rows(doneDuring(b.id, in: day), calendar: calendar) : []
        let also = rows(laid.hidden.map(\.block), calendar: calendar)
        return CalendarHoverInfo(
            id: b.id,
            kind: kind,
            kindLabel: Copywriter.calendarHoverKind(kind),
            title: b.title,
            time: point ? Copywriter.trackerClock(r.start, calendar: calendar) : Fmt.shortRange(r.start, r.end, calendar: calendar),
            length: point ? nil : Copywriter.calendarBlockLength(r),
            meta: meta(of: b, lookup: lookup),
            doneDuringTitle: done.isEmpty ? nil : Copywriter.calendarHoverDoneDuring,
            doneDuring: done,
            alsoHereTitle: also.isEmpty ? nil : Copywriter.calendarHoverAlsoHere,
            alsoHere: also,
            actions: actions(of: b, kind: kind, lookup: lookup)
        )
    }

    private static func doneDuring(_ eventID: String, in day: [CalendarLaidBlock]) -> [CalendarBlock] {
        day.flatMap { [$0] + $0.hidden }.filter { $0.doneDuring == eventID }.map(\.block)
    }

    private static func kind(of b: CalendarBlock) -> CalendarHoverKind {
        switch b.source {
        case .event: return .event
        case .todo: return .todo
        case let .activity(a, _): return a.kind == .away ? .away : .activity
        }
    }

    private static func meta(of b: CalendarBlock, lookup: CalendarHoverLookup) -> String? {
        switch b.source {
        case let .event(e):
            let copies = b.copies > 1 ? Copywriter.calendarCopiesSpoken(b.copies) : nil
            let parts = [lookup.calendarNames[e.calendarID], copies].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: Copywriter.calendarHoverMetaSeparator)
        case let .todo(id):
            return lookup.todoListNames[id]
        case let .activity(a, _):
            return a.kind == .away ? a.awayPlaceLabel : a.category ?? Copywriter.trackerNoCategory
        }
    }

    private static func actions(of b: CalendarBlock, kind: CalendarHoverKind, lookup: CalendarHoverLookup) -> [CalendarHoverAction] {
        switch b.source {
        case let .event(e):
            let start: [CalendarHoverAction] = CalendarEventStart.allows(e, now: lookup.now, trackerOn: lookup.trackerOn) ? [.startAsActivity] : []
            return start + (lookup.readOnlyEventIDs.contains(e.id) ? [.openInCalendar] : [.edit, .openInCalendar])
        case .todo:
            return [.markDone, .edit, .openInReminders]
        case let .activity(_, running):
            if running { return [] }
            if kind == .away { return [.editAway] }
            return b.activityIDs.count > 1 ? [.edit] : [.edit, .delete]
        }
    }
}
