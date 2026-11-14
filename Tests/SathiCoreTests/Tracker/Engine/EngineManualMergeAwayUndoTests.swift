import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine manual merge waits for Welcome back")
struct EngineManualMergeAwayUndoTests {
    private func welcomeBackAfterMergedIdle() -> (EngineHarness, Activity, Activity) {
        let mail = Activity(text: "Mail", category: "Work", start: wed(9), end: wed(9, 40))
        let gaming = Activity(text: "Gaming", category: "Break", start: wed(9, 50), end: wed(10))
        let h = EngineHarness.tracker(at: wed(10), activities: [mail, gaming]) { $0.prefs.tracker.askEveryMinutes = 30 }
        h.engine.startActivity(ActivityDraft(text: "Gaming", category: "Break", length: .open, calendarID: nil))
        h.presence.idleSeconds = 10 * 60
        h.advance(minutes: 30)
        h.presence.idleSeconds = 30 * 60
        h.advance(minutes: 20)
        h.presence.idleSeconds = 0
        h.advance(minutes: 10)
        #expect(h.running == nil)
        return (h, mail, gaming)
    }

    @Test func mergeIsBlockedWhileWelcomeBackWaits() {
        let (h, mail, gaming) = welcomeBackAfterMergedIdle()
        let before = h.saved
        #expect(h.engine.mergeCheck([mail.id, gaming.id]) == .blocked(.awayUndo))
        #expect(h.engine.mergeActivities([mail.id, gaming.id]) == .blocked(.awayUndo))
        #expect(h.saved == before)
    }

    @Test func mergeWorksAfterWelcomeBackIsAnswered() {
        let (h, mail, gaming) = welcomeBackAfterMergedIdle()
        h.engine.iWasHere()
        #expect(h.running?.text == "Gaming")
        #expect(h.engine.mergeActivities([mail.id, gaming.id]) == .merged(mail.id))
        #expect(h.saved.filter { $0.kind == .work }.count == 1)
    }

    @Test func blockedCopy() {
        #expect(Copywriter.mergeBlocked(.awayUndo) == "Wait until the Welcome back question is answered.")
    }
}
