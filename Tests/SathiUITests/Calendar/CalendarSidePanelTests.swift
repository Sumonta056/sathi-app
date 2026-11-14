import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar side panel toggle")
struct CalendarSidePanelTests {
    private let coding = Activity(text: "Coding", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 11))

    private func harness(shown: Bool) -> EngineHarness {
        EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [coding])) {
            $0.prefs.tracker.isOn = true
            $0.prefs.calendarPage.sidePanelShown = shown
        }
    }

    private func page(
        _ h: EngineHarness,
        _ kind: ReportRange,
        editing: CalendarActivityEdit? = nil
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range, editing: editing).environmentObject(h.engine).inspect()
    }

    @Test func hiddenPanelLeavesTheGridAndTheSummary() throws {
        let h = harness(shown: false)
        for kind in ReportRange.allCases {
            let sut = try page(h, kind)
            #expect((try? sut.find(CalendarStatsPanel.self)) == nil)
            #expect(throws: Never.self) { try sut.find(CalendarHeaderSummary.self) }
            #expect(throws: Never.self) { try sut.find(text: "Tracked 1 h 00 m · Planned 0 m") }
        }
    }

    @Test func theHeaderButtonHidesThePanel() throws {
        let h = harness(shown: true)
        try Find.button(page(h, .week), label: "Hide side panel").tap()
        #expect(h.engine.data.prefs.calendarPage.sidePanelShown == false)
    }

    @Test func theHeaderButtonShowsTheHiddenPanel() throws {
        let h = harness(shown: false)
        try Find.button(page(h, .day), label: "Show side panel").tap()
        #expect(h.engine.data.prefs.calendarPage.sidePanelShown == true)
    }

    @Test func theEditPanelStillOpensWhileThePanelIsHidden() throws {
        let h = harness(shown: false)
        let edit = CalendarActivityEdit(day: DayKey(coding.start, calendar: h.engine.rangeCalendar), target: .activity(coding.id))
        let sut = try page(h, .day, editing: edit)
        #expect(throws: Never.self) { try sut.find(ActivityEditPanel.self) }
    }
}
