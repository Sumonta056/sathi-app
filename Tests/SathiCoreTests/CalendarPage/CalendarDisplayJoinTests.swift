import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarDisplayJoin")
struct CalendarDisplayJoinTests {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func row(_ text: String, _ from: Int, _ to: Int, kind: ActivityKind = .work, category: String? = "Focus", extraSeconds: Int = 0) -> Activity {
        Activity(
            kind: kind, text: text, category: category,
            start: t0.addingTimeInterval(TimeInterval(from * 60)),
            end: t0.addingTimeInterval(TimeInterval(to * 60 + extraSeconds))
        )
    }

    @Test func closeRowsJoinIntoOneGroup() {
        let groups = CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec", 34, 60)])
        #expect(groups.count == 1)
        #expect(groups[0].count == 2)
    }

    @Test func gapOfFiveMinutesAndOneSecondSplits() {
        let b = row("Spec", 35, 60).withStart(t0.addingTimeInterval(30 * 60 + 5 * 60 + 1))
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), b]).count == 2)
    }

    @Test func gapOfExactlyFiveMinutesJoins() {
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec", 35, 60)]).count == 1)
    }

    @Test func caseDiffersSplits() {
        #expect(CalendarDisplayJoin.groups([row("spec", 0, 30), row("Spec", 31, 60)]).count == 2)
    }

    @Test func categoryDiffersSplits() {
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec", 31, 60, category: "Other")]).count == 2)
    }

    @Test func awayRowsNeverJoin() {
        let rows = [row("", 0, 30, kind: .away), row("", 31, 60, kind: .away)]
        #expect(CalendarDisplayJoin.groups(rows).count == 2)
    }

    @Test func differentKindsDoNotJoin() {
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec", 31, 60, kind: .buddy)]).count == 2)
    }

    @Test func overlappingRowsDoNotJoin() {
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec", 20, 60)]).count == 2)
    }

    @Test func trimmedTextIsEqual() {
        #expect(CalendarDisplayJoin.groups([row("Spec", 0, 30), row("Spec ", 31, 60)]).count == 1)
    }

    @Test func inputIsUnchanged() {
        let rows = [row("Spec", 0, 30), row("Spec", 34, 60)]
        let copy = rows
        _ = CalendarDisplayJoin.groups(rows)
        #expect(rows == copy)
    }

    @Test func joinedBlockCarriesAllRowIDs() {
        let rows = [row("Spec", 0, 30), row("Spec", 34, 60)]
        let blocks = CalendarBlockBuilder.blocks(events: [], activities: rows, running: nil, colors: [:], joins: true)
        #expect(blocks.count == 1)
        #expect(blocks[0].activityIDs.count == 2)
        #expect(blocks[0].interval == DateInterval(start: rows[0].start, end: rows[1].end))
    }

    @Test func dayViewKeepsEveryRow() {
        let rows = [row("Spec", 0, 30), row("Spec", 34, 60)]
        let blocks = CalendarBlockBuilder.blocks(events: [], activities: rows, running: nil, colors: [:], joins: false)
        #expect(blocks.count == 2)
    }
}

private extension Activity {
    func withStart(_ date: Date) -> Activity {
        var copy = self
        copy.start = date.wholeSecond
        return copy
    }
}
