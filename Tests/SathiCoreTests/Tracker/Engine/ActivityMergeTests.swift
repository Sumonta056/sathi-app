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

    @Test func twoOwnEventsDoNotMerge() {
        let later = row(from: wed(10, 10), to: wed(10, 20), event: "b")
        #expect(!ActivityMerge.canMerge(row(event: "a"), later))
        #expect(ActivityMerge.canMerge(row(event: "a"), row(from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func calendarSourcedRowsDoNotMerge() {
        #expect(!ActivityMerge.canMerge(row(source: "s"), row(from: wed(10, 10), to: wed(10, 20))))
    }

    @Test func mergedListJoinsRuns() {
        let rows = [
            row(from: wed(10), to: wed(10, 10)),
            row(from: wed(10, 10), to: wed(10, 20)),
            row(from: wed(10, 20), to: wed(10, 30)),
            row("Mail", category: "Break", from: wed(10, 30), to: wed(10, 40)),
            row(from: wed(10, 40), to: wed(10, 50))
        ]
        let out = ActivityMerge.merged(rows)
        #expect(out.map(\.text) == ["Gaming", "Mail", "Gaming"])
        #expect(out[0].id == rows[0].id)
        #expect(out[0].start == wed(10) && out[0].end == wed(10, 30))
    }
}
