import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
enum CalendarMergeSupport {
    final class Box {
        var selected: Set<ActivityID> = []
        var error: String?
        var opened: [String] = []
        var selectedBinding: Binding<Set<ActivityID>> { Binding(get: { self.selected }, set: { self.selected = $0 }) }
        var errorBinding: Binding<String?> { Binding(get: { self.error }, set: { self.error = $0 }) }
    }

    static let first = Activity(text: "Write", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 30))
    static let second = Activity(text: "Review", category: "Coding", start: day(2026, 3, 4, 10, 30), end: day(2026, 3, 4, 11))
    static let late = Activity(text: "Late", category: "Coding", start: day(2026, 3, 4, 23), end: day(2026, 3, 4, 23, 30))
    static let after = Activity(text: "After", category: "Coding", start: day(2026, 3, 5, 1), end: day(2026, 3, 5, 1, 30))
    static let standup = CalendarEventInfo(
        id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 9, 30), calendarID: "work"
    )

    static func harness(_ rows: [Activity]) -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: rows)) { $0.prefs.tracker.isOn = true }
        h.calendarWriter.eventsValue = [standup]
        return h
    }

    static func range(_ h: EngineHarness, _ kind: ReportRange = .day) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
    }

    static func block(_ h: EngineHarness, _ title: String) throws -> CalendarBlock {
        try #require(h.engine.calendarPage(range(h)).blocks.first { $0.title == title })
    }

    static func strip(_ h: EngineHarness, _ box: Box, canUndo: Bool = false) -> CalendarMergeStrip {
        CalendarMergeStrip(
            rows: CalendarMergePick.rows(h.engine.calendarPage(range(h)).blocks), calendar: h.engine.rangeCalendar,
            canUndo: canUndo, actions: .merging(h.engine), selected: box.selectedBinding, error: box.errorBinding
        )
    }
}
