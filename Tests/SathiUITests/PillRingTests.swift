import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Pill ring")
struct PillRingTests {
    private let start = day(2026, 3, 4, 22)
    private let end = day(2026, 3, 4, 22, 15)

    @Test(arguments: [(0, 1.0), (5, 2.0 / 3), (15, 0.0), (20, 0.0)])
    func ringShowsTheRemainingPart(_ minutes: Int, _ expected: Double) {
        let now = start.addingTimeInterval(Double(minutes) * 60)
        #expect(abs(PillRing.fraction(start: start, end: end, now: now) - expected) < 0.0001)
    }

    @Test func staleNowBeforeTheStartShowsAFullRing() {
        let now = start.addingTimeInterval(-120)
        #expect(PillRing.fraction(start: start, end: end, now: now) == 1)
    }

    @Test func emptySessionShowsAnEmptyRing() {
        #expect(PillRing.fraction(start: start, end: start, now: start) == 0)
    }
}
