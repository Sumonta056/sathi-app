import Foundation
import SathiCore
import Testing

@Suite("Activity merge rule")
struct ActivityMergeTests {
    private func row(
        _ text: String = "Gaming", category: String? = "Break", from s: Date = wed(10), to e: Date = wed(10, 10),
        kind: ActivityKind = .work, event: String? = nil, source: String? = nil
    ) -> Activity {
        Activity(kind: kind, text: text, category: category, start: s, end: e, eventID: event, sourceEventID: source)
    }

    @Test func sameTextAndCategoryTouchingMerge() {
        #expect(ActivityMerge.canMerge(row(), row(from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func gapOfAMinuteMergesButMoreDoesNot() {
        #expect(ActivityMerge.canMerge(row(), row(from: wed(10, 11), to: wed(10, 20))))
        #expect(!ActivityMerge.canMerge(row(), row(from: wed(10, 11, s: 1), to: wed(10, 20))))
    }

    @Test func overlapDoesNotMerge() {
        #expect(!ActivityMerge.canMerge(row(), row(from: wed(10, 9), to: wed(10, 20))))
    }

    @Test func textIsTrimmedAndCaseSensitive() {
        #expect(ActivityMerge.canMerge(row(), row(" Gaming ", from: wed(10, 10), to: wed(10, 20))))
        #expect(!ActivityMerge.canMerge(row(), row("gaming", from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func differentCategoryDoesNotMerge() {
        #expect(!ActivityMerge.canMerge(row(), row(category: nil, from: wed(10, 10), to: wed(10, 20))))
        #expect(!ActivityMerge.canMerge(row(), row("Gaming", category: "Coding", from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func onlyWorkMerges() {
        for kind in [ActivityKind.away, .event, .timeBlock, .buddy] {
            #expect(!ActivityMerge.canMerge(row(kind: kind), row(from: wed(10, 10), to: wed(10, 20), kind: kind)))
        }
    }

    @Test func twoOwnEventsMergeAndKeepTheEarlierEvent() {
        let later = row(from: wed(10, 10), to: wed(10, 20), event: "b")
        #expect(ActivityMerge.canMerge(row(event: "a"), later))
        #expect(ActivityMerge.joined(row(event: "a"), later).eventID == "a")
        #expect(ActivityMerge.canMerge(row(event: "a"), row(from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func calendarSourcedRowsDoNotMerge() {
        #expect(!ActivityMerge.canMerge(row(source: "s"), row(from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func aLaterRowThatAloneHasAnEventBringsItsCalendar() {
        var first = row()
        first.calendarID = "X"
        var second = row(from: wed(10, 10), to: wed(10, 20), event: "ev-y")
        second.calendarID = "Y"
        let joined = ActivityMerge.joined(first, second)
        #expect(joined.eventID == "ev-y")
        #expect(joined.calendarID == "Y")
        #expect(joined.id == first.id)
    }

    @Test func theEarlierCalendarWinsWhenTheEventIsNotTakenOver() {
        var first = row(event: "ev-x")
        first.calendarID = "X"
        var second = row(from: wed(10, 10), to: wed(10, 20))
        second.calendarID = "Y"
        #expect(ActivityMerge.joined(first, second).calendarID == "X")
    }
}
