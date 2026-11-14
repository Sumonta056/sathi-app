import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page edit")
struct CalendarPageEditTests {
    private let standup = CalendarEventInfo(id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work")
    private let coding = Activity(text: "Coding", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 11))

    private func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [coding])) {
            $0.prefs.tracker.isOn = true
        }
        h.calendarWriter.eventsValue = [standup]
        return h
    }

    private func range(_ h: EngineHarness, _ kind: ReportRange) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: kind, calendar: h.engine.rangeCalendar)
    }

    private func block(_ h: EngineHarness, _ title: String) throws -> CalendarBlock {
        try #require(h.engine.calendarPage(range(h, .day)).blocks.first { $0.title == title })
    }

    @Test func anEventBlockOpensThePopoverWithItsValues() throws {
        let h = harness()
        let open = try CalendarPage.open(block(h, "Standup"), engine: h.engine)
        #expect(open == .event(h.engine.calendarPageForm(for: standup)))
    }

    @Test func anActivityBlockOpensTheEditPanelOnItsDay() throws {
        let h = harness()
        let open = try CalendarPage.open(block(h, "Coding"), engine: h.engine)
        let key = DayKey(coding.start, calendar: h.engine.rangeCalendar)
        #expect(open == .activity(CalendarActivityEdit(day: key, target: .activity(coding.id))))
    }

    @Test func anEmptySlotOpensANewEventAtTheSlot() {
        let h = harness()
        let form = CalendarPage.newEvent(at: day(2026, 3, 4, 14, 20), engine: h.engine)
        #expect(form.eventID == nil)
        #expect(form.start == day(2026, 3, 4, 14, 15))
        #expect(form.end == day(2026, 3, 4, 14, 45))
    }

    @Test func theEditPanelShowsForAnOpenActivity() throws {
        let h = harness()
        let edit = CalendarActivityEdit(day: DayKey(coding.start, calendar: h.engine.rangeCalendar), target: .activity(coding.id))
        let sut = try CalendarPage(range: range(h, .day), editing: edit).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(ActivityEditPanel.self) }
        #expect((try? sut.find(CalendarStatsPanel.self)) == nil)
    }

    @Test func dayShowsThePanelAndNoLine() throws {
        let h = harness()
        let sut = try CalendarPage(range: range(h, .day)).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarStatsPanel.self) }
        #expect((try? sut.find(CalendarStatsLine.self)) == nil)
    }

    @Test func weekAndMonthShowTheLineAndThePanel() throws {
        let h = harness()
        for kind in [ReportRange.week, .month] {
            let sut = try CalendarPage(range: range(h, kind)).environmentObject(h.engine).inspect()
            #expect(throws: Never.self) { try sut.find(CalendarStatsPanel.self) }
            #expect(throws: Never.self) { try sut.find(CalendarStatsLine.self) }
        }
    }

    @Test func aTapOnABlockCallsTheBlockAction() throws {
        let h = harness()
        let data = h.engine.calendarPage(range(h, .day))
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        let math = CalendarGridMath(day: key, calendar: h.engine.rangeCalendar, hourHeight: UIMetrics.calendarHourHeight)
        var tapped: [String] = []
        var actions = CalendarGridActions()
        actions.block = { _, b, _ in tapped.append(b.title) }
        let column = CalendarDayColumn(
            day: key, placed: CalendarBlockLayout.place(data.blocks, within: math.interval), texts: data.texts, math: math,
            now: nil, categories: ActivityCategory.defaults, calendar: h.engine.rangeCalendar, actions: actions
        )
        try column.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: "Standup") != nil }.tap()
        #expect(tapped == ["Standup"])
    }
}
