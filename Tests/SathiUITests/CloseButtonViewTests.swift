import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Close button views")
struct CloseButtonViewTests {
    @Test(arguments: ReminderSurface.allCases)
    func closeShowsAtNudgeByDefault(_ s: ReminderSurface) throws {
        let h = s.harness()
        #expect(h.engine.phase(s.id) == .bubble(.nudge))
        #expect(try hasDismiss(s.inspect(h, .nudge)))
    }

    @Test(arguments: ReminderSurface.allCases)
    func closeIsHiddenAtPersist(_ s: ReminderSurface) throws {
        let h = s.persisting()
        #expect(h.engine.phase(s.id) == .bubble(.persist))
        #expect(try !hasDismiss(s.inspect(h, .persist)))
    }

    @Test(arguments: ReminderSurface.allCases)
    func closeTapIsASnoozeOfThatHabitOnly(_ s: ReminderSurface) throws {
        let h = s.harness()
        let others = HabitID.allCases.filter { $0 != s.id }
        let before = others.map { h.engine.state($0) }
        try Find.button(s.inspect(h, .nudge), label: "Dismiss").tap()
        #expect(h.engine.state(s.id).snoozes == 1)
        #expect(h.engine.activities[s.id] == nil)
        #expect(h.history.appended.last == .snooze(s.id, at: h.clock.now))
        #expect(others.map { h.engine.state($0) } == before)
    }
}
