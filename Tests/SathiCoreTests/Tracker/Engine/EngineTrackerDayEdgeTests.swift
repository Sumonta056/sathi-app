import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker day edges")
struct EngineTrackerDayEdgeTests {
    @Test func afterTrackerHoursARunningActivityContinuesAndStillOnItAsks() {
        let h = EngineHarness.tracker(at: wed(17, 30))
        h.start(minutes: 60)
        h.advance(minutes: 60)
        #expect(h.running != nil)
        #expect(h.promptKind == .stillOnIt)
    }

    @Test func afterTrackerHoursNoNewWhatNowShows() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 30)
        #expect(h.promptKind == nil)
        #expect(h.trackerShows == [.whatNow])
    }

    @Test func anActivityNeverCrossesMidnight() {
        let h = EngineHarness.tracker(at: wed(23, 30)) {
            $0.prefs.tracker.endOfDayOn = false
            $0.prefs.tracker.askEveryMinutes = 60
        }
        h.start(minutes: 60)
        h.advance(minutes: 45)
        #expect(h.running == nil)
        #expect(h.saved.first?.end == day(2026, 3, 5))
        #expect(h.promptKind == nil)
    }

    @Test func theMidnightIsADeadline() {
        let h = EngineHarness.tracker(at: wed(23, 59, s: 50))
        h.start(minutes: 60)
        h.engine.stillOnIt(minutes: 60)
        #expect(h.engine.nextTickDelay() <= 10)
    }

    @Test func endOfDayShowsOnceAtTheEndOfHoursWhenNothingRuns() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 10)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 1)
        #expect(h.engine.trackerEndOfDayState() != nil)
        h.engine.closeTrackerEndOfDay()
        h.advance(minutes: 60)
        #expect(h.presenter.trackerCalls.filter { $0 == .showEndOfDay }.count == 1)
        #expect(h.store.live.tracker.lastEndOfDay == DayKey(wed(18), calendar: .current))
    }

    @Test func endOfDayWaitsForTheRunningActivityToEnd() {
        let h = EngineHarness.tracker(at: wed(17, 30))
        h.start(minutes: 60)
        h.advance(minutes: 40)
        #expect(!h.presenter.trackerCalls.contains(.showEndOfDay))
        h.engine.doneActivity()
        h.engine.skipTrackerPrompt()
        h.engine.tick()
        #expect(h.presenter.trackerCalls.contains(.showEndOfDay))
    }

    @Test func endOfDayIsOffWhenTheUserTurnsItOff() {
        let h = EngineHarness.tracker(at: wed(17, 50)) { $0.prefs.tracker.endOfDayOn = false }
        h.advance(minutes: 20)
        #expect(!h.presenter.trackerCalls.contains(.showEndOfDay))
    }

    @Test func openFullReportOpensTheActivitiesReportOnThatDay() {
        let h = EngineHarness.tracker(at: wed(17, 50))
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 10)
        h.engine.trackerEndOfDayState()?.openReport()
        #expect(h.engine.activityReportDay == DayKey(wed(18), calendar: .current))
        #expect(h.presenter.calls.last == .showMain(.activities(DayKey(wed(18), calendar: .current))))
        #expect(h.presenter.trackerCalls.last == .closeEndOfDay)
    }
}
