import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Scheduler")
struct SchedulerTests {
    private let s = Scheduler(prefs: Prefs())

    @Test func nextWaterDueInsideHours() {
        #expect(s.nextWaterDue(after: day(2026, 3, 4, 10)) == day(2026, 3, 4, 12))
    }

    @Test func nextWaterDueBeforeStartSnapsToStart() {
        #expect(s.nextWaterDue(after: day(2026, 3, 4, 5)) == day(2026, 3, 4, 9, 30))
    }

    @Test func nextWaterDueAfterEndMovesToNextMorning() {
        #expect(s.nextWaterDue(after: day(2026, 3, 4, 17)) == day(2026, 3, 5, 9, 30))
    }

    @Test func inWaterHoursBoundaries() {
        #expect(!s.inWaterHours(day(2026, 3, 4, 9, 29)))
        #expect(s.inWaterHours(day(2026, 3, 4, 9, 30)))
        #expect(s.inWaterHours(day(2026, 3, 4, 18, 29)))
        #expect(!s.inWaterHours(day(2026, 3, 4, 18, 30)))
    }

    @Test func nextReadingDueToday() {
        #expect(s.nextReadingDue(now: day(2026, 3, 4, 10), readToday: 0, skipToday: false) == day(2026, 3, 4, 22))
    }

    @Test func nextReadingDueTomorrowWhenDoneOrSkipped() {
        let now = day(2026, 3, 4, 10)
        #expect(s.nextReadingDue(now: now, readToday: 15, skipToday: false) == day(2026, 3, 5, 22))
        #expect(s.nextReadingDue(now: now, readToday: 0, skipToday: true) == day(2026, 3, 5, 22))
    }

    @Test func nextWaterStart() {
        #expect(s.nextWaterStart(after: day(2026, 3, 4, 6)) == day(2026, 3, 4, 9, 30))
        #expect(s.nextWaterStart(after: day(2026, 3, 4, 20)) == day(2026, 3, 5, 9, 30))
    }

    @Test func minutesOfDay() {
        #expect(s.minutesOfDay(day(2026, 3, 4, 13, 45)) == 825)
    }
}
