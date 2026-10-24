import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("DayClock")
struct DayClockTests {
    private let clock = DayClock()

    @Test func minutesOfDay() {
        #expect(clock.minutesOfDay(day(2026, 3, 4, 13, 45)) == 825)
    }

    @Test func minutesOfDayAtMidnightIsZero() {
        #expect(clock.minutesOfDay(day(2026, 3, 4)) == 0)
    }

    @Test func atBuildsTheTimeOnThatDay() {
        #expect(clock.at(570, on: day(2026, 3, 4, 17)) == day(2026, 3, 4, 9, 30))
        #expect(clock.at(1320, on: day(2026, 3, 4, 1)) == day(2026, 3, 4, 22))
    }

    @Test func atZeroIsStartOfDay() {
        #expect(clock.at(0, on: day(2026, 3, 4, 13, 45)) == day(2026, 3, 4))
    }
}
