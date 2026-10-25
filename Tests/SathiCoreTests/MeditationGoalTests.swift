import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Meditation goal")
struct MeditationGoalTests {
    private func rules(goal: Int = 10, every interval: Int = 60) -> MeditationRules {
        var prefs = Prefs()
        prefs.meditation.dailyGoalMinutes = goal
        prefs.meditation.intervalMinutes = interval
        prefs.meditation.startMinutes = 9 * 60
        prefs.meditation.endMinutes = 21 * 60
        return MeditationRules(prefs: prefs)
    }

    @Test func newDefaults() {
        let m = MeditationPrefs()
        #expect(m.dailyGoalMinutes == 10)
        #expect(m.sessionMinutes == 2)
        #expect(m.intervalMinutes == 60)
        #expect(m.startMinutes == 9 * 60)
        #expect(m.endMinutes == 21 * 60)
        #expect(Limits.meditationGoals == [5, 10, 20])
        #expect(Limits.meditationLengths == [1, 2, 5])
    }

    @Test func oldFileWithSlotsKeepsItsOtherSettings() throws {
        let json = #"{"enabled":true,"slots":["morning","evening"],"sessionMinutes":5,"style":"relax","chime":false,"strictness":"persistent"}"#
        let m = try JSONDecoder().decode(MeditationPrefs.self, from: Data(json.utf8))
        #expect(m.enabled)
        #expect(m.sessionMinutes == 5)
        #expect(m.style == .relax)
        #expect(!m.chime)
        #expect(m.strictness == .persistent)
        #expect(m.dailyGoalMinutes == 10)
        #expect(m.intervalMinutes == 60)
    }

    @Test func newFieldsRoundTrip() throws {
        var m = MeditationPrefs()
        m.dailyGoalMinutes = 20
        m.intervalMinutes = 90
        m.startMinutes = 7 * 60 + 45
        m.endMinutes = 22 * 60 + 15
        let back = try JSONDecoder().decode(MeditationPrefs.self, from: JSONEncoder().encode(m))
        #expect(back == m)
    }

    @Test func goalIsTheDailyGoalMinutes() {
        #expect(rules(goal: 20).dailyGoal == 20)
    }

    @Test func nextReminderIsOneIntervalAfterTheLastSession() {
        let next = rules().nextDue(now: day(2026, 3, 4, 10), lastDone: day(2026, 3, 4, 10), doneToday: 2, skipToday: false)
        #expect(next == day(2026, 3, 4, 11))
    }

    @Test func reminderBeforeTheStartMovesToTheStart() {
        let next = rules().nextDue(now: day(2026, 3, 4, 7), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 9))
    }

    @Test func reminderAfterTheEndMovesToTomorrowsStart() {
        let next = rules().nextDue(now: day(2026, 3, 4, 20, 30), lastDone: day(2026, 3, 4, 20, 30), doneToday: 4, skipToday: false)
        #expect(next == day(2026, 3, 5, 9))
    }

    @Test func goalMetMeansNoMoreRemindersToday() {
        let next = rules(goal: 5).nextDue(now: day(2026, 3, 4, 10), lastDone: day(2026, 3, 4, 10), doneToday: 6, skipToday: false)
        #expect(next == day(2026, 3, 5, 9))
    }

    @Test func aZeroGoalNeverCountsAsMet() {
        let next = rules(goal: 0).nextDue(now: day(2026, 3, 4, 10), lastDone: day(2026, 3, 4, 10), doneToday: 0, skipToday: false)
        #expect(next == day(2026, 3, 4, 11))
    }

    @Test func activeOnlyBetweenStartAndEnd() {
        let r = rules()
        #expect(!r.isActiveTime(day(2026, 3, 4, 8, 59)))
        #expect(r.isActiveTime(day(2026, 3, 4, 9)))
        #expect(!r.isActiveTime(day(2026, 3, 4, 21)))
        #expect(r.nextActiveStart(after: day(2026, 3, 4, 22)) == day(2026, 3, 5, 9))
    }

    @Test func strictIsKeptForMeditationButNotForReading() {
        var prefs = Prefs()
        prefs.meditation.strictness = .strict
        prefs.reading.strictness = .strict
        #expect(prefs.strictness(.meditation) == .strict)
        #expect(prefs.strictness(.reading) == .persistent)
    }

    @Test func strictMeditationLocksAfterTwoSnoozesAndTheLockStartsASession() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.strictness = .strict
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
        }
        h.showReminder(.meditation)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.meditation) == .lock)
        #expect(h.presenter.calls.contains(.showLock(.meditation)))
        h.engine.lockConfirmed(.meditation)
        #expect(h.engine.phase(.meditation) == .session)
        #expect(h.presenter.calls.contains(.closeLock))
    }

    @Test func meetingTheGoalStopsRemindersForTheDay() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 5
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
        }
        h.engine.startMeditation()
        h.advance(minutes: 5)
        let shown = h.presenter.calls.filter { $0 == .showBubble(.meditation, .nudge) }.count
        h.advance(minutes: 11 * 60)
        #expect(h.presenter.calls.filter { $0 == .showBubble(.meditation, .nudge) }.count == shown)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 9))
    }
}
