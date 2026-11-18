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
    case merge
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

    package init(calendarNames: [String: String] = [:], readOnlyEventIDs: Set<String> = [], todoListNames: [String: String] = [:]) {
        self.calendarNames = calendarNames
        self.readOnlyEventIDs = readOnlyEventIDs
        self.todoListNames = todoListNames
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
    package var childrenTitle: String?
    package var children: [CalendarHoverChild]
    package var actions: [CalendarHoverAction]

    package static func make(_ placed: CalendarPlacedBlock, lookup: CalendarHoverLookup, calendar: Calendar) -> CalendarHoverInfo {
        let b = placed.block
        let span = placed.span
        let kind = kind(of: b)
        let children = placed.children.map {
            CalendarHoverChild(
                id: $0.block.id, title: $0.block.title,
                time: Copywriter.trackerSpan($0.span.start, $0.span.end, calendar: calendar)
            )
        }
        let point = span.duration == 0
        return CalendarHoverInfo(
            id: b.id,
            kind: kind,
            kindLabel: Copywriter.calendarHoverKind(kind),
            title: b.title,
            time: point
                ? Copywriter.trackerClock(span.start, calendar: calendar)
                : Copywriter.trackerSpan(span.start, span.end, calendar: calendar),
            length: point ? nil : Copywriter.trackerDuration(span.duration),
            meta: meta(of: b, lookup: lookup),
            childrenTitle: children.isEmpty ? nil : Copywriter.calendarHoverChildren,
            children: children,
            actions: actions(of: b, kind: kind, lookup: lookup)
        )
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
            return lookup.readOnlyEventIDs.contains(e.id)
                ? [.startAsActivity, .openInCalendar]
                : [.startAsActivity, .edit, .openInCalendar]
        case .todo:
            return [.markDone, .edit, .openInReminders]
        case .activity:
            return kind == .away ? [.editAway] : [.edit, .merge, .delete]
        }
    }
}
