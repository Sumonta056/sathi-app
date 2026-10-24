import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading weekdays")
struct EngineReadingWeekdaysTests {
    private var allButWednesday: Set<Weekday> { Set(Weekday.allCases).subtracting([.wednesday]) }

    @Test func turningTodayOffReschedulesReadingToTheNextSelectedDay() {
        let h = EngineHarness()
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 4, 22))
        h.engine.data.prefs.reading.weekdays = allButWednesday
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
    }

    @Test func turningTodayOffSkipsTwoDaysWhenTomorrowIsAlsoOff() {
        let h = EngineHarness()
        h.engine.data.prefs.reading.weekdays = [.friday]
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 6, 22))
    }

    @Test func aDayThatIsOffNeverShowsTheReadingReminder() {
        let h = EngineHarness {
            $0.prefs.water.enabled = false
            $0.prefs.reading.weekdays = Set(Weekday.allCases).subtracting([.wednesday])
        }
        h.advance(minutes: 12 * 60 + 30)
        #expect(!h.presenter.calls.contains(.showBubble(.reading, .nudge)))
        #expect(h.engine.phase == .idle)
    }
}
