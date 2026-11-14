import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar merge strip")
struct CalendarMergeStripTests {
    typealias Fix = CalendarMergeSupport
    typealias Box = Fix.Box

    private var first: Activity { Fix.first }
    private var second: Activity { Fix.second }

    private func strip(_ h: EngineHarness, _ box: Box) -> CalendarMergeStrip { Fix.strip(h, box) }

    @Test func withNothingSelectedTheHintShows() throws {
        let h = Fix.harness([first, second])
        let sut = try strip(h, Box()).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.calendarMergeHint) }
        #expect(throws: (any Error).self) { try sut.find(ActivityMergeBar.self) }
    }

    @Test func oneSelectedBlockShowsTheBarWithTheTooFewLine() throws {
        let h = Fix.harness([first, second])
        let box = Box()
        box.selected = [first.id]
        let sut = try strip(h, box).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.mergeBlocked(.tooFew)) }
        #expect(throws: (any Error).self) { try sut.find(text: Copywriter.calendarMergeHint) }
    }

    @Test func twoBlocksShowThePreviewAndMergeThroughTheEngine() throws {
        let h = Fix.harness([first, second])
        let box = Box()
        box.selected = [first.id, second.id]
        let sut = try strip(h, box).inspect()
        try sut.find(button: Copywriter.mergeButton).tap()
        #expect(h.engine.activityDay(DayKey(first.start, calendar: h.engine.rangeCalendar)).activities.count == 1)
        #expect(box.selected.isEmpty)
        #expect(h.engine.mergeUndo != nil)
    }

    @Test func blocksAfterMidnightGiveTheDifferentDaysLine() throws {
        let h = Fix.harness([Fix.late, Fix.after])
        let box = Box()
        box.selected = [Fix.late.id, Fix.after.id]
        let sut = try strip(h, box).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.mergeBlocked(.differentDays)) }
    }

    @Test func theCheckDoesNotRunAgainForTheSameSelection() throws {
        var checks = 0
        let h = Fix.harness([first, second])
        var a = ActivityDayActions.merging(h.engine)
        let real = a.mergeCheck
        a.mergeCheck = { checks += 1; return real($0) }
        let box = Box()
        box.selected = [first.id, second.id]
        let sut = CalendarMergeStrip(
            rows: CalendarMergePick.rows(h.engine.calendarPage(Fix.range(h)).blocks), calendar: h.engine.rangeCalendar,
            canUndo: false, actions: a, selected: box.selectedBinding, error: box.errorBinding
        )
        _ = try sut.inspect().find(ActivityMergeBar.self)
        _ = try sut.inspect().find(ActivityMergeBar.self)
        #expect(checks == 1)
    }
}
