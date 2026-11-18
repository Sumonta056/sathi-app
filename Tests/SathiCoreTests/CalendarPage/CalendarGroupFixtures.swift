import Foundation
@testable import SathiCore

enum Grp {
    static let least: Double = 26

    static func act(_ id: String, _ from: Int, _ to: Int, title: String? = nil, category: String? = nil, running: Bool = false) -> CalendarBlock {
        let a = Activity(text: title ?? id, category: category, start: Lay.at(from), end: Lay.at(to))
        return CalendarBlock(
            id: id, title: title ?? id, interval: Lay.span(from, to), style: .activity(category: category),
            source: .activity(a, running: running), isAllDay: false, activityIDs: [a.id]
        )
    }

    static func place(_ blocks: [CalendarBlock], narrow: Set<CalendarLaneShape> = []) -> [CalendarPlacedBlock] {
        CalendarBlockLayout.place(blocks, minimumMinutes: least, narrow: narrow)
    }

    static func shown(_ blocks: [CalendarBlock], narrow: Set<CalendarLaneShape> = []) -> [String: CalendarPlacedBlock] {
        Lay.byID(place(blocks, narrow: narrow))
    }

    static func groups(_ placed: [CalendarPlacedBlock]) -> [[String]] {
        placed.compactMap { $0.block.group.map { $0.members.map(\.id) } }
    }

    static func everyID(_ placed: [CalendarPlacedBlock]) -> Set<String> {
        Set(placed.flatMap { p in [p] + p.children + p.hidden }.flatMap { p -> [String] in
            p.block.group.map { $0.members.map(\.id) } ?? [p.block.id]
        })
    }
}
