import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar merge")
struct CalendarMergeTests {
    typealias Fix = CalendarMergeSupport
    typealias Box = Fix.Box

    private var first: Activity { Fix.first }
    private var second: Activity { Fix.second }

    private func harness(_ rows: [Activity]) -> EngineHarness { Fix.harness(rows) }

    private func range(_ h: EngineHarness, _ kind: ReportRange = .day) -> CalendarPageRange { Fix.range(h, kind) }

    private func block(_ h: EngineHarness, _ title: String) throws -> CalendarBlock { try Fix.block(h, title) }

    private func actions(_ h: EngineHarness, _ box: Box, kind: ReportRange = .day, command: Bool = true) -> CalendarGridActions {
        var focus = CalendarPageFocus()
        let focusBinding = Binding(get: { focus }, set: { focus = $0 })
        var a = CalendarGridActions.page(
            kind: kind, engine: h.engine, focus: focusBinding, selected: box.selectedBinding, error: box.errorBinding
        )
        a.command = { command }
        let inner = a.block
        a.block = { box.opened.append($1.title); inner($0, $1, $2) }
        return a
    }

    private func press(_ a: CalendarGridActions, _ block: CalendarBlock) {
        a.press(DayKey(day(2026, 3, 4, 12), calendar: Calendar(identifier: .gregorian)), block, 0)
    }

    @Test func aCommandClickOnAnActivityTogglesItsSelection() throws {
        let h = harness([first, second])
        let box = Box()
        let a = actions(h, box)
        try press(a, block(h, "Write"))
        #expect(box.selected == [first.id])
        try press(a, block(h, "Write"))
        #expect(box.selected.isEmpty)
        #expect(box.opened.isEmpty)
    }

    @Test func aCommandClickClearsTheErrorLine() throws {
        let h = harness([first])
        let box = Box()
        box.error = "old"
        try press(actions(h, box), block(h, "Write"))
        #expect(box.error == nil)
    }

    @Test func aPlainClickOpensTheBlockAndKeepsTheSelection() throws {
        let h = harness([first, second])
        let box = Box()
        box.selected = [second.id]
        try press(actions(h, box, command: false), block(h, "Write"))
        #expect(box.selected == [second.id])
        #expect(box.opened == ["Write"])
    }

    @Test func aCommandClickOnAnEventOpensItInstead() throws {
        let h = harness([first])
        let box = Box()
        try press(actions(h, box), block(h, "Standup"))
        #expect(box.selected.isEmpty)
        #expect(box.opened == ["Standup"])
    }

    @Test func theRunningActivityCannotBeSelected() throws {
        let h = harness([first])
        h.engine.startActivity(ActivityDraft(text: "Focus", length: .minutes(60)))
        h.advance(minutes: 20)
        let running = try #require(h.engine.calendarPage(range(h)).blocks.first {
            if case .activity(_, running: true) = $0.source { true } else { false }
        })
        let box = Box()
        press(actions(h, box), running)
        #expect(box.selected.isEmpty)
    }

    @Test func weekAndMonthHaveNoSelection() throws {
        let h = harness([first, second])
        for kind in [ReportRange.week, .month] {
            let box = Box()
            let a = actions(h, box, kind: kind)
            #expect(a.toggle == nil)
            try press(a, block(h, "Write"))
            #expect(box.selected.isEmpty)
            #expect(box.opened == ["Write"])
        }
    }

    @Test func rowsThatLeftThePageLeaveTheSelection() {
        let kept = CalendarMergePick.pruned([first.id, second.id], in: [first])
        #expect(kept == [first.id])
    }

    @Test func theRowsAreTheActivityBlocksOfTheDay() {
        let h = harness([first, second])
        let rows = CalendarMergePick.rows(h.engine.calendarPage(range(h)).blocks)
        #expect(Set(rows.map(\.id)) == [first.id, second.id])
    }

    @Test func aSelectedBlockGetsTheThickBorder() {
        #expect(CalendarBlockFit.border(selected: true) > CalendarBlockFit.border(selected: false))
    }

    @Test func theDayPageHoldsTheStripAndTheWeekPageDoesNot() throws {
        let h = harness([first, second])
        let day = try CalendarPage(range: range(h)).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try day.find(CalendarMergeStrip.self) }
        let week = try CalendarPage(range: range(h, .week)).environmentObject(h.engine).inspect()
        #expect(throws: (any Error).self) { try week.find(CalendarMergeStrip.self) }
    }
}
