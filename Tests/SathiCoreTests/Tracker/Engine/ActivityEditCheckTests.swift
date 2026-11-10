import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity edit check")
struct ActivityEditCheckTests {
    private let calendar = Calendar.current

    private func edit(_ start: Date, _ end: Date) -> ActivityEdit {
        ActivityEdit(text: "x", category: nil, start: start, end: end)
    }

    @Test func anEditOverMidnightIsRefused() {
        let e = edit(wed(23, 30), day(2026, 3, 5, 0, 30))
        #expect(ActivityEditCheck.problem(e, others: [], calendar: calendar) == .crossesMidnight)
    }

    @Test func anEditThatEndsAtMidnightIsFine() {
        #expect(ActivityEditCheck.problem(edit(wed(23), day(2026, 3, 5)), others: [], calendar: calendar) == nil)
    }

    @Test func overMidnightWinsOverOverlap() {
        let others = [DateInterval(start: wed(23, 40), end: wed(23, 50))]
        #expect(ActivityEditCheck.problem(edit(wed(23, 30), day(2026, 3, 5, 0, 30)), others: others, calendar: calendar) == .crossesMidnight)
    }

    @Test func theMidnightCopyIsTheSpecText() {
        #expect(Copywriter.trackerEditCrossesMidnight == "An activity cannot cross midnight.")
    }
}
