import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Manual merge check")
struct ManualMergeTests {
    private let cal = Calendar.current

    private func row(
        _ text: String, _ h1: Int, _ h2: Int, kind: ActivityKind = .work, category: String? = "Work",
        event: String? = nil, calendar: String? = nil, source: String? = nil,
        place: AwayPlace? = nil, placeName: String? = nil
    ) -> Activity {
        Activity(
            kind: kind, text: text, category: category, start: wed(h1), end: wed(h2), awayPlace: place,
            calendarID: calendar, eventID: event, sourceEventID: source, awayPlaceName: placeName
        )
    }

    private func check(_ selected: [Activity], in rows: [Activity]) -> ManualMergeCheck {
        ManualMergeCheck.check(Set(selected.map(\.id)), dayRows: rows, calendar: cal)
    }

    private func plan(_ c: ManualMergeCheck) -> ManualMergePlan? {
        if case let .ok(p) = c { return p }
        return nil
    }

    private func block(_ c: ManualMergeCheck) -> ManualMergeBlock? {
        if case let .blocked(b) = c { return b }
        return nil
    }

    @Test func twoWorkRowsWithAGapMerge() throws {
        let a = row("Code", 9, 10, calendar: "cal"), b = row("Mail", 11, 12)
        let p = try #require(plan(check([a, b], in: [a, b])))
        #expect(p.merged.id == a.id)
        #expect(p.merged.text == "Code")
        #expect(p.merged.category == "Work")
        #expect(p.merged.start == wed(9))
        #expect(p.merged.end == wed(12))
        #expect(p.rows.map(\.id) == [a.id, b.id])
    }

    @Test func differentTextsMerge() {
        let a = row("Code", 9, 10), b = row("Lunch talk", 10, 11, category: "Break")
        #expect(plan(check([a, b], in: [a, b])) != nil)
    }

    @Test func unnamedAwayBetweenIsRemoved() throws {
        let a = row("Code", 9, 10), away = row("", 10, 11, kind: .away), b = row("Mail", 11, 12)
        let p = try #require(plan(check([a, b], in: [a, away, b])))
        #expect(p.removedAway.map(\.id) == [away.id])
    }

    @Test func unnamedAwayInsideTheSelectionIsRemoved() throws {
        let a = row("Code", 9, 10), away = row("", 10, 11, kind: .away), b = row("Mail", 11, 12)
        let p = try #require(plan(check([a, away, b], in: [a, away, b])))
        #expect(p.removedAway.map(\.id) == [away.id])
        #expect(p.rows.map(\.id) == [a.id, b.id])
    }

    @Test func unsortedInputStillUsesTheFirstRow() throws {
        let a = row("Code", 9, 10), b = row("Mail", 11, 12)
        let p = try #require(plan(check([b, a], in: [b, a])))
        #expect(p.merged.id == a.id)
    }

    @Test func oneRowIsTooFew() {
        let a = row("Code", 9, 10), b = row("Mail", 11, 12)
        #expect(block(check([a], in: [a, b])) == .tooFew)
        #expect(block(ManualMergeCheck.check([], dayRows: [a, b], calendar: cal)) == .tooFew)
    }

    @Test func unknownIdIsNotStored() {
        let a = row("Code", 9, 10), ghost = row("Running", 11, 12)
        #expect(block(check([a, ghost], in: [a])) == .notStored)
    }

    @Test func rowsOnTwoDatesAreDifferentDays() {
        let a = row("Code", 9, 10)
        let b = Activity(text: "Mail", start: wed(9).addingTimeInterval(86400), end: wed(10).addingTimeInterval(86400))
        #expect(block(check([a, b], in: [a, b])) == .differentDays)
    }

    @Test func selectedEventRowsBlock() {
        let a = row("Code", 9, 10), ev = row("Standup", 10, 11, kind: .event), src = row("Mail", 11, 12, source: "e1")
        #expect(block(check([a, ev], in: [a, ev])) == .eventRow)
        #expect(block(check([a, src], in: [a, src])) == .eventRow)
    }

    @Test func buddyAndTimeBlockRowsBlock() {
        let a = row("Code", 9, 10), buddy = row("Water", 10, 11, kind: .buddy), tb = row("Focus", 10, 11, kind: .timeBlock)
        #expect(block(check([a, buddy], in: [a, buddy])) == .buddyRow)
        #expect(block(check([a, tb], in: [a, tb])) == .timeBlockRow)
    }

    @Test func namedAwayBlocks() {
        let a = row("Code", 9, 10), b = row("Mail", 11, 12)
        let lunch = row("", 10, 11, kind: .away, place: .lunch)
        let custom = row("", 10, 11, kind: .away, placeName: "Gym")
        #expect(block(check([a, b], in: [a, lunch, b])) == .namedAway)
        #expect(block(check([a, b], in: [a, custom, b])) == .namedAway)
        #expect(block(check([a, lunch, b], in: [a, lunch, b])) == .namedAway)
    }

    @Test func unselectedWorkRowBetweenBlocks() {
        let a = row("Code", 9, 10), mid = row("Mail", 10, 11), b = row("Docs", 11, 12)
        #expect(block(check([a, b], in: [a, mid, b])) == .rowBetween)
    }

    @Test func buddyAndEventRowsBetweenBlockWithTheirOwnReason() {
        let a = row("Code", 9, 10), b = row("Docs", 11, 12)
        let buddy = row("Water", 10, 11, kind: .buddy), ev = row("Standup", 10, 11, kind: .event)
        let src = row("Mail", 10, 11, source: "e1"), tb = row("Focus", 10, 11, kind: .timeBlock)
        #expect(block(check([a, b], in: [a, buddy, b])) == .buddyRow)
        #expect(block(check([a, b], in: [a, ev, b])) == .eventRow)
        #expect(block(check([a, b], in: [a, src, b])) == .eventRow)
        #expect(block(check([a, b], in: [a, tb, b])) == .timeBlockRow)
    }

    @Test func rowsOutsideTheSpanAreIgnored() {
        let before = row("Early", 7, 8), a = row("Code", 9, 10), b = row("Mail", 11, 12), after = row("Late", 13, 14)
        #expect(plan(check([a, b], in: [before, a, b, after])) != nil)
    }

    @Test func firstRowWithAnEventIsKept() throws {
        let a = row("Code", 9, 10), b = row("Mail", 10, 11, event: "e2", calendar: "c2")
        let c = row("Docs", 11, 12, event: "e3", calendar: "c3")
        let p = try #require(plan(check([a, b, c], in: [a, b, c])))
        #expect(p.keptEventRow?.id == b.id)
        #expect(p.droppedEventRows.map(\.id) == [c.id])
        #expect(p.merged.id == a.id)
        #expect(p.merged.eventID == "e2")
        #expect(p.merged.calendarID == "c2")
    }

    @Test func firstRowEventStaysWhenItHasOne() throws {
        let a = row("Code", 9, 10, event: "e1", calendar: "c1"), b = row("Mail", 10, 11, event: "e2", calendar: "c2")
        let p = try #require(plan(check([a, b], in: [a, b])))
        #expect(p.keptEventRow?.id == a.id)
        #expect(p.droppedEventRows.map(\.id) == [b.id])
        #expect(p.merged.eventID == "e1")
        #expect(p.merged.calendarID == "c1")
    }

    @Test func noEventsMeansNothingKeptOrDropped() throws {
        let a = row("Code", 9, 10), b = row("Mail", 11, 12)
        let p = try #require(plan(check([a, b], in: [a, b])))
        #expect(p.keptEventRow == nil)
        #expect(p.droppedEventRows.isEmpty)
        #expect(p.merged.eventID == nil)
    }

    @Test func previewLine() {
        let line = Copywriter.mergePreview(count: 3, start: wed(9), end: wed(12, 30), calendar: cal)
        let s = Copywriter.quickClock(wed(9), calendar: cal), e = Copywriter.quickClock(wed(12, 30), calendar: cal)
        #expect(line == "3 rows become 1, \(s) to \(e)")
    }

    @Test func everyBlockHasItsOwnLine() {
        let all: [ManualMergeBlock] = [.tooFew, .notStored, .differentDays, .eventRow, .buddyRow, .timeBlockRow, .namedAway, .rowBetween]
        #expect(Set(all.map(Copywriter.mergeBlocked)).count == all.count)
        #expect(Limits.manualMergeMinRows == 2)
        #expect(Timing.mergeUndoShow == 30)
    }
}
