import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Tracker presenter")
struct TrackerPresenterTests {
    private func setUp(_ configure: (EngineHarness) -> Void = { _ in }) -> (EngineHarness, UIController) {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10)) { $0.prefs.meditation.enabled = true }
        configure(h)
        let ui = UIController()
        ui.engine = h.engine
        return (h, ui)
    }

    private func draft(_ quiet: Bool = false) -> ActivityDraft {
        ActivityDraft(text: "Code review", category: "Coding", length: .minutes(30), askOffsetMinutes: 0, quiet: quiet)
    }

    @Test func whatNowShowsInTheCornerWithoutTakingTheKeyboard() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
        ui.showTrackerPrompt(.whatNow)
        let p = try #require(ui.trackerPromptPanel)
        #expect(ui.corner.contains { $0 === p })
        #expect(p.becomesKeyOnlyIfNeeded)
        #expect(!p.isKeyWindow)
        #expect(p.frame.width > 0 && p.frame.height > 0)
        #expect(!UIController.trackerPromptTakesKeyboard(h.engine.trackerPrompt, byUser: h.engine.trackerPromptByUser))
        ui.closeTrackerPrompt(.whatNow)
        #expect(ui.trackerPromptPanel == nil)
        #expect(ui.corner.isEmpty)
    }

    @Test func whatNowAfterDoneTakesTheKeyboard() {
        let (h, _) = setUp()
        h.engine.startActivity(draft())
        h.engine.doneActivity()
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
        #expect(UIController.trackerPromptTakesKeyboard(h.engine.trackerPrompt, byUser: h.engine.trackerPromptByUser))
    }

    @Test func stillOnItNeverTakesTheKeyboard() {
        let prompt = PromptState(kind: .stillOnIt, shownAt: day(2026, 3, 4, 10), askTime: day(2026, 3, 4, 10))
        #expect(!UIController.trackerPromptTakesKeyboard(prompt, byUser: true))
    }

    @Test func centerPanelShowsInTheMiddleOutsideTheCorner() throws {
        let (h, ui) = setUp()
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        let p = try #require(ui.trackerPromptPanel)
        #expect(!ui.corner.contains { $0 === p })
        #expect(UIController.trackerPromptTakesKeyboard(h.engine.trackerPrompt, byUser: h.engine.trackerPromptByUser))
        ui.closeTrackerPrompt(.center)
        #expect(ui.trackerPromptPanel == nil)
    }

    @Test func trackerPromptSitsBelowBuddyPopupsThatOpenLater() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        ui.showBubble(.meditation, .nudge)
        let tracker = try #require(ui.trackerPromptPanel)
        let buddy = try #require(ui.bubbles[.meditation])
        #expect(ui.corner.first === buddy)
        #expect(ui.corner.last === tracker)
        #expect(tracker.frame.maxY < buddy.frame.maxY || tracker.frame.maxX < buddy.frame.minX)
        ui.closeBubble(.meditation)
        ui.closeTrackerPrompt(h.engine.trackerPrompt?.kind ?? .whatNow)
    }

    @Test func onlyOneTrackerPromptPanelAtATime() {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        #expect(ui.trackerPromptKind == .center)
        #expect(ui.corner.isEmpty)
        ui.closeTrackerPrompt(.center)
    }

    @Test func noteShowsInTheCornerAndCloses() {
        let (h, ui) = setUp()
        let event = CalendarEventInfo(id: "e1", title: "Standup", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 15), calendarID: "c")
        ui.showTrackerNote(.event(event))
        #expect(ui.trackerNotePanel != nil)
        #expect(ui.corner.count == 1)
        ui.closeTrackerNote()
        #expect(ui.trackerNotePanel == nil)
        #expect(ui.corner.isEmpty)
        withExtendedLifetime(h) {}
    }

    @Test func endOfDayShowsCenteredAndCloses() {
        let (h, ui) = setUp()
        h.engine.startActivity(draft())
        h.advance(minutes: 30)
        h.engine.doneActivity()
        h.engine.skipTrackerPrompt()
        h.advance(minutes: 8 * 60)
        ui.showTrackerEndOfDay()
        #expect(ui.trackerEndOfDayPanel != nil)
        #expect(ui.corner.isEmpty)
        ui.closeTrackerEndOfDay()
        #expect(ui.trackerEndOfDayPanel == nil)
    }
}
