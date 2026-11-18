import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page display join")
struct EngineCalendarPageJoinTests {
    private let a = Activity(text: "Code", category: "Coding", start: wed(10), end: wed(10, 30))
    private let b = Activity(text: "Code", category: "Coding", start: wed(10, 34), end: wed(11))

    private func codeSpans(_ h: EngineHarness, _ kind: ReportRange) -> [DateInterval] {
        h.engine.calendarPageBase(.containing(wed(12), kind: kind, calendar: h.engine.calendar)).blocks
            .filter { $0.title == "Code" }
            .map(\.interval)
    }

    @Test(arguments: [ReportRange.week, .month])
    func weekAndMonthDrawOneJoinedBlock(_ kind: ReportRange) {
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        #expect(codeSpans(h, kind) == [DateInterval(start: wed(10), end: wed(11))])
    }

    @Test func dayDrawsEveryRow() {
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        #expect(codeSpans(h, .day) == [DateInterval(start: wed(10), end: wed(10, 30)), DateInterval(start: wed(10, 34), end: wed(11))])
    }

    @Test func joiningLeavesTheSavedRowsAsTheyAre() {
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        _ = codeSpans(h, .week)
        _ = codeSpans(h, .month)
        #expect(h.saved == [a, b])
        #expect(h.activities.saves == 0)
    }
}
