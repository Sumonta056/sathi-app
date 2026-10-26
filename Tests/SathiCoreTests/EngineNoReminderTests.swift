import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine no reminder")
struct EngineNoReminderTests {
    private func neverDue(water: Bool = false) -> EngineHarness {
        gymHarness(at: day(2026, 3, 4, 9)) {
            $0.prefs.gym.startMinutes = 15 * 60
            $0.prefs.gym.endMinutes = 16 * 60
            $0.prefs.gym.intervalMinutes = 60
            $0.prefs.water.enabled = water
        }
    }

    @Test func pillSaysNoReminder() {
        let h = neverDue()
        #expect(h.engine.state(.gym).nextDue == .distantFuture)
        #expect(h.engine.pill(.gym) == "No reminder")
    }

    @Test func habitWithNoReminderIsLeftOutOfTheMenuBar() {
        let h = neverDue()
        #expect(h.engine.focus == nil)
        #expect(h.engine.statusText == "Sathi")
    }

    @Test func otherHabitKeepsTheMenuBarCountdown() {
        let h = neverDue(water: true)
        #expect(h.engine.focus == .water)
        #expect(h.engine.statusText == Fmt.short(h.engine.remaining(.water)))
    }

    @Test func notNowWithNoNextReminderShowsNoSnoozedNote() {
        let h = neverDue()
        h.engine.trigger(.gym)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.engine.notNow(.gym)
        #expect(!h.presenter.calls.contains { if case .showSnoozed = $0 { return true }; return false })
        #expect(h.engine.pill(.gym) == "No reminder")
        #expect(h.engine.focus == nil)
    }
}
