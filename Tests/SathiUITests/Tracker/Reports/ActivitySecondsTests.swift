import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edits keep whole seconds")
struct ActivitySecondsTests {
    typealias Fix = ActivityViewSupport

    private let dayStart = Fix.key(4).start(in: Fix.calendar)

    private func activity(_ start: Date, _ end: Date) -> Activity {
        Activity(text: "B", category: nil, start: start, end: end)
    }

    @Test func aTextOnlyEditKeepsTheExactTimes() {
        let b = activity(Fix.at(4, 9, 7, 42), Fix.at(4, 10, 0, 13))
        var draft = ActivityEditDraft(b, calendar: Fix.calendar)
        draft.text = "New"
        let edit = draft.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(edit.start == b.start)
        #expect(edit.end == b.end)
    }

    @Test func changingOnlyTheEndKeepsTheStartSeconds() {
        let b = activity(Fix.at(4, 9, 7, 42), Fix.at(4, 10, 0))
        var draft = ActivityEditDraft(b, calendar: Fix.calendar)
        draft.endMinutes = 11 * 60
        let edit = draft.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(edit.start == b.start)
        #expect(edit.end == Fix.at(4, 11, 0))
    }

    @Test func changingTheStartUsesTheWholeMinute() {
        let b = activity(Fix.at(4, 9, 7, 42), Fix.at(4, 10, 0))
        var draft = ActivityEditDraft(b, calendar: Fix.calendar)
        draft.startMinutes = 9 * 60 + 10
        #expect(draft.edit(dayStart: dayStart, calendar: Fix.calendar).start == Fix.at(4, 9, 10))
    }

    @Test func anActivityEndingAtMidnightStaysValid() {
        let late = activity(Fix.at(4, 23, 30), Fix.at(5, 0, 0))
        var draft = ActivityEditDraft(late, calendar: Fix.calendar)
        draft.text = "Late"
        #expect(draft.edit(dayStart: dayStart, calendar: Fix.calendar).end == Fix.at(5, 0, 0))
    }

    @Test func pickingMidnightAsTheEndMeansTheNextMidnight() {
        let late = activity(Fix.at(4, 22, 0), Fix.at(4, 23, 0))
        var draft = ActivityEditDraft(late, calendar: Fix.calendar)
        draft.endMinutes = 0
        #expect(draft.edit(dayStart: dayStart, calendar: Fix.calendar).end == Fix.at(5, 0, 0))
    }

    @Test func aFillKeepsTheGapBoundaries() {
        let gapStart = Fix.at(4, 9, 7, 42)
        let draft = ActivityEditDraft(start: gapStart, end: Fix.at(4, 10, 0), calendar: Fix.calendar)
        let edit = draft.edit(dayStart: dayStart, calendar: Fix.calendar)
        #expect(edit.start == gapStart)
    }

    @Test func anActivityOutsideHoursStaysInTheLogAndCount() {
        let outside = Fix.item("Night fix", "Coding", 4, (20, 0), (21, 0))
        let day = Fix.day(4, [outside])
        #expect(ActivityLogRows.make(day).contains(.activity(outside, running: false)))
        #expect(ActivityDayStats(day).count == 1)
    }

    @Test func logRowsAreSortedByStart() {
        let rows = ActivityLogRows.make(Fix.day())
        let starts = rows.map { row -> Date in
            switch row {
            case let .activity(a, _): return a.start
            case let .gap(i): return i.start
            }
        }
        #expect(starts == starts.sorted())
    }
}
