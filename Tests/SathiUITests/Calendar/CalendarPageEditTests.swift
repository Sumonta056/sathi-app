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
        try #require(h.engine.calendarPageBase(range(h, .day)).blocks.first { $0.title == title })
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

    private func runningHarness() throws -> (EngineHarness, CalendarBlock) {
        let h = harness()
        h.engine.startActivity(ActivityDraft(text: "Focus", length: .minutes(60)))
        h.advance(minutes: 20)
        let running = try #require(h.engine.calendarPageBase(range(h, .day)).blocks.first {
            if case .activity(_, running: true) = $0.source { true } else { false }
        })
        return (h, running)
    }

    @Test func theRunningBlockOpensNothing() throws {
        let (h, running) = try runningHarness()
        #expect(CalendarPage.open(running, engine: h.engine) == nil)
    }

    @Test func aClickOnTheRunningBlockStoresNoTarget() throws {
        let (h, running) = try runningHarness()
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        var focus = CalendarPageFocus()
        CalendarPage.tap(running, day: key, y: 0, engine: h.engine, focus: &focus)
        #expect(focus.editing == nil)
        #expect(focus.popover == nil)
        h.engine.startActivity(ActivityDraft(text: "Next", length: .minutes(30)))
        let sut = try CalendarPage(range: range(h, .day), editing: focus.editing).environmentObject(h.engine).inspect()
        #expect((try? sut.find(ActivityEditPanel.self)) == nil)
    }

    @Test func aClickOnAStoredActivityOpensItsPanel() throws {
        let h = harness()
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        var focus = CalendarPageFocus()
        try CalendarPage.tap(block(h, "Coding"), day: key, y: 0, engine: h.engine, focus: &focus)
        #expect(focus.editing?.target == .activity(coding.id))
        #expect(focus.popover == nil)
        try CalendarPage.tap(block(h, "Standup"), day: key, y: 40, engine: h.engine, focus: &focus)
        #expect(focus.editing == nil)
        #expect(focus.popover?.form == h.engine.calendarPageForm(for: standup))
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

    @Test func everyViewShowsThePanelAndTheHeaderSummaryAndNoLine() throws {
        let h = harness()
        h.engine.setCalendarSidePanelShown(true, for: .week)
        for kind in ReportRange.allCases {
            let sut = try CalendarPage(range: range(h, kind)).environmentObject(h.engine).inspect()
            #expect(throws: Never.self) { try sut.find(CalendarStatsPanel.self) }
            #expect(throws: Never.self) { try sut.find(CalendarPageHeader.self).find(CalendarHeaderSummary.self) }
            let texts = sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
            #expect(!texts.contains { $0.hasPrefix("Tracked this") })
        }
    }

    @Test func aTapOnABlockCallsTheBlockAction() throws {
        let h = harness()
        let data = h.engine.calendarPage(range(h, .day), metrics: CalendarSplitMetrics.metrics(kind: .day, rowMinutes: 60, narrow: false))
        let key = DayKey(day(2026, 3, 4, 12), calendar: h.engine.rangeCalendar)
        let grid = try #require(data.grid)
        let blocks = grid.days[key] ?? []
        let standup = try #require(blocks.first { $0.block.title == "Standup" })
        var tapped: [String] = []
        var actions = CalendarGridActions()
        actions.block = { _, b, _ in tapped.append(b.title) }
        let column = CalendarSplitColumn(
            day: key, kind: .day, blocks: blocks, grid: grid, width: 500, now: nil, calendar: h.engine.rangeCalendar,
            categories: ActivityCategory.defaults, actions: actions
        )
        try column.inspect().find(viewWithAccessibilityIdentifier: "calendar.split.block." + standup.id).callOnTapGesture()
        #expect(tapped == ["Standup"])
    }
}
