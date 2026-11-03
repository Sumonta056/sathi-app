import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Quick time")
struct QuickTimeTests {
    private let calendar = Calendar.current

    @Test func inMinutesAddsWholeMinutes() {
        let now = day(2026, 3, 4, 10, 0).addingTimeInterval(0.4)
        #expect(QuickTime.inMinutes(15).date(now: now, calendar: calendar) == day(2026, 3, 4, 10, 15))
    }

    @Test func atLaterMinuteIsToday() {
        let due = QuickTime.at(minutes: 14 * 60 + 37).date(now: day(2026, 3, 4, 10), calendar: calendar)
        #expect(due == day(2026, 3, 4, 14, 37))
    }

    @Test func atPastMinuteGoesTomorrow() {
        let now = day(2026, 3, 4, 10, 0)
        #expect(QuickTime.at(minutes: 10 * 60).date(now: now, calendar: calendar) == day(2026, 3, 5, 10, 0))
        #expect(QuickTime.at(minutes: 9 * 60).date(now: now, calendar: calendar) == day(2026, 3, 5, 9, 0))
    }

    @Test func atTheSameMinuteWithSecondsGoesTomorrow() {
        let now = day(2026, 3, 4, 10, 0).addingTimeInterval(30)
        #expect(QuickTime.at(minutes: 10 * 60).date(now: now, calendar: calendar) == day(2026, 3, 5, 10, 0))
    }

    @Test(arguments: [0, 1, 59, 600, 1439, -5, 5000])
    func atIsAlwaysAfterNow(_ minutes: Int) {
        let now = day(2026, 3, 4, 10, 0).addingTimeInterval(0.7)
        let due = QuickTime.at(minutes: minutes).date(now: now, calendar: calendar)
        #expect(due > now)
        #expect(due.timeIntervalSince(now) <= Timing.day + Timing.hour)
    }

    @Test func atAcrossTheSpringForwardGapStaysAfterNow() throws {
        let cal = FixedZone.newYork.calendar
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3, minute: 30)))
        let due = QuickTime.at(minutes: 2 * 60 + 30).date(now: now, calendar: cal)
        #expect(due > now)
        #expect(due.timeIntervalSince(now) <= Timing.day + Timing.hour)
    }

    @Test func cleanTrimsJoinsAndCuts() {
        #expect(QuickText.clean("  Call\nmom  ") == "Call mom")
        #expect(QuickText.clean(String(repeating: "a", count: 90)).count == Limits.quickTextMax)
    }

    @Test func cleanTurnsEachLineBreakIntoOneSpace() {
        #expect(QuickText.clean("a\r\nb\nc") == "a b c")
        #expect(QuickText.clean("\n \n") == "")
    }
}
