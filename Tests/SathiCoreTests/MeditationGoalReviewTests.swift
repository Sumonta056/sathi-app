import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Meditation goal review")
struct MeditationGoalReviewTests {
    private func strictBoth(at start: Date = day(2026, 3, 4, 10)) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.strictness = .strict
            $0.prefs.water.strictness = .strict
            $0.prefs.reading.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 4, 9, 59)
        }
    }

    @Test func onlyOneLockShowsAndTheOtherHabitIsNotStuck() {
        let h = strictBoth()
        h.showReminder(.water)
        h.showReminder(.meditation)
        h.engine.snooze(.water)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        h.engine.snooze(.water)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
        #expect(!h.presenter.calls.contains(.showLock(.meditation)))
        h.engine.logWater(1)
        #expect(h.engine.phase(.water) == .idle)
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
    }

    @Test func oldSlotsFileKeepsItsGoal() throws {
        let json = #"{"enabled":true,"slots":["morning","evening"],"sessionMinutes":2}"#
        let m = try JSONDecoder().decode(MeditationPrefs.self, from: Data(json.utf8))
        #expect(m.dailyGoalMinutes == 4)
        let three = #"{"slots":["morning","afternoon","evening"],"sessionMinutes":10}"#
        #expect(try JSONDecoder().decode(MeditationPrefs.self, from: Data(three.utf8)).dailyGoalMinutes == 30)
        let saved = #"{"slots":["morning"],"sessionMinutes":2,"dailyGoalMinutes":20}"#
        #expect(try JSONDecoder().decode(MeditationPrefs.self, from: Data(saved.utf8)).dailyGoalMinutes == 20)
    }

    @Test func anEmergencySkipLastsTheDayAfterASettingsChange() {
        let h = strictBoth()
        h.engine.emergencySkip(.meditation)
        h.engine.data.prefs.water.intervalMinutes = 60
        h.advance(minutes: 60)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 9))
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
    }

    @Test func goalMetAroundADSTNightIsDueNextMorning() throws {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        var prefs = Prefs()
        prefs.meditation.dailyGoalMinutes = 5
        let rules = MeditationRules(prefs: prefs, calendar: ny)
        let night = try #require(ny.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 22, minute: 30)))
        let next = rules.nextDue(now: night, lastDone: night, doneToday: 5, skipToday: false)
        #expect(try next == #require(ny.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 9))))
        let late = try #require(ny.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 20, minute: 30)))
        let after = rules.nextDue(now: late, lastDone: late, doneToday: 2, skipToday: false)
        #expect(try after == #require(ny.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 9))))
        let fallBack = try #require(ny.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 30)))
        let nextDay = rules.nextDue(now: fallBack, lastDone: fallBack, doneToday: 5, skipToday: false)
        #expect(try nextDay == #require(ny.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9))))
    }
}
