import Foundation

package struct CalendarBlockGroup: Equatable, Sendable {
    package var members: [CalendarBlock]
    package var badge: String?
    package var detail: String?
    package var categories: [String?]

    package init(members: [CalendarBlock], badge: String? = nil, detail: String? = nil, categories: [String?] = []) {
        self.members = members
        self.badge = badge
        self.detail = detail
        self.categories = categories
    }

    package static func block(_ members: [CalendarBlock], column: String? = nil) -> CalendarBlock {
        let first = members[0]
        let end = members.map(\.interval.end).max() ?? first.interval.end
        let span = DateInterval(start: first.interval.start, end: max(first.interval.start, end))
        let longest = members.dropFirst().reduce(first) { $1.interval.duration > $0.interval.duration ? $1 : $0 }
        let same = members.allSatisfy { trimmed($0.title) == trimmed(first.title) }
        let lead = same ? first : longest.interval.duration >= span.duration * Limits.calendarGroupLeadShare ? longest : nil
        let others = members.count - 1
        let group = CalendarBlockGroup(
            members: members,
            badge: same ? Copywriter.calendarCopies(members.count) : lead.map { _ in Copywriter.calendarHiddenCount(others) },
            detail: lead == nil ? detail(members) : nil,
            categories: categories(members)
        )
        return CalendarBlock(
            id: [groupMark, column, longest.id].compactMap { $0 }.joined(separator: idSeparator),
            title: lead.map { trimmed($0.title) } ?? Copywriter.calendarGroupTitle(members.count),
            interval: span,
            style: longest.style,
            source: (lead ?? longest).source,
            isAllDay: false,
            activityIDs: members.flatMap(\.activityIDs),
            group: group
        )
    }

    static let groupMark = "g"
    static let idSeparator = "-"

    private static func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func detail(_ members: [CalendarBlock]) -> String {
        let ranked = members.enumerated().sorted {
            $0.element.interval.duration != $1.element.interval.duration
                ? $0.element.interval.duration > $1.element.interval.duration
                : $0.offset < $1.offset
        }
        var titles: [String] = []
        for m in ranked where !titles.contains(trimmed(m.element.title)) {
            titles.append(trimmed(m.element.title))
        }
        return titles.prefix(Limits.calendarGroupDetailTitles).joined(separator: Copywriter.calendarGroupDetailSeparator)
    }

    private static func categories(_ members: [CalendarBlock]) -> [String?] {
        var seen: [String?] = []
        for c in members.map(category(of:)) where !seen.contains(c) {
            seen.append(c)
        }
        return seen
    }

    static func category(of b: CalendarBlock) -> String? {
        switch b.style {
        case let .activity(c), let .joined(c): return c
        default: return nil
        }
    }
}
