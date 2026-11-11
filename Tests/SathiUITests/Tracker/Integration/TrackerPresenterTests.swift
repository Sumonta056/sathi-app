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

    @Test func whatNowShowsAtTheCenterWithoutTakingTheKeyboard() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
        ui.showTrackerPrompt(.whatNow)
        let p = try #require(ui.trackerPromptPanel)
        #expect(!ui.corner.contains { $0 === p })
        #expect(!p.isKeyWindow)
        #expect(!ui.trackerPromptHasKeys)
        #expect(p.frame.width > 0 && p.frame.height > 0)
        #expect(!h.engine.trackerPromptTakesKeyboard)
        ui.closeTrackerPrompt(.whatNow)
        #expect(ui.trackerPromptPanel == nil)
        #expect(ui.corner.isEmpty)
    }

    @Test func whatNowAfterDoneTakesTheKeyboard() {
        let (h, _) = setUp()
        h.engine.startActivity(draft())
        h.engine.doneActivity()
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
        #expect(h.engine.trackerPromptTakesKeyboard)
    }

    @Test func welcomeBackNoLongerTakesTheKeyboard() {
        let (h, _) = setUp()
        h.engine.data.live.tracker.prompt = PromptState(kind: .welcomeBack, shownAt: day(2026, 3, 4, 10), askTime: day(2026, 3, 4, 10))
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func centerPanelShowsInTheMiddleOutsideTheCorner() throws {
        let (h, ui) = setUp()
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        let p = try #require(ui.trackerPromptPanel)
        #expect(!ui.corner.contains { $0 === p })
        #expect(h.engine.trackerPromptTakesKeyboard)
        #expect(ui.trackerPromptHasKeys)
        ui.closeTrackerPrompt(.center)
        #expect(ui.trackerPromptPanel == nil)
    }

    @Test func buddyPopupsNeverShareTheCornerWithTheTrackerPrompt() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        ui.showBubble(.meditation, .nudge)
        let tracker = try #require(ui.trackerPromptPanel)
        let buddy = try #require(ui.bubbles[.meditation])
        #expect(ui.corner.count == 1)
        #expect(ui.corner.first === buddy)
        #expect(!ui.corner.contains { $0 === tracker })
        ui.closeBubble(.meditation)
        ui.closeTrackerPrompt(h.engine.trackerPrompt?.kind ?? .whatNow)
    }

    @Test func aNewReasonReplacesTheContentOfTheSamePanel() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        let first = try #require(ui.trackerPromptPanel)
        let center = NSPoint(x: first.frame.midX, y: first.frame.midY)
        h.engine.data.live.tracker.prompt = PromptState(kind: .stillOnIt, shownAt: h.clock.now, askTime: h.clock.now)
        ui.showTrackerPrompt(.stillOnIt)
        #expect(ui.trackerPromptPanel === first)
        #expect(ui.trackerPromptKind == .stillOnIt)
        #expect(first.isVisible)
        #expect(abs(first.frame.midX - center.x) < 1)
        #expect(abs(first.frame.midY - center.y) < 1)
        ui.closeTrackerPrompt(.stillOnIt)
        #expect(ui.trackerPromptPanel == nil)
    }

    @Test func theShortcutOverAScheduledPromptKeepsThePanelAndTakesTheKeyboard() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        let first = try #require(ui.trackerPromptPanel)
        #expect(!ui.trackerPromptHasKeys)
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        #expect(ui.trackerPromptPanel === first)
        #expect(ui.trackerPromptKind == .center)
        #expect(ui.trackerPromptHasKeys)
        ui.trackerReturnApp = nil
        ui.closeTrackerPrompt(.center)
    }

    @Test func aReRenderOfTheSamePromptKeepsTheDraft() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        let model = try #require(ui.trackerPromptModel)
        model.draft.text = "Typed by hand"
        ui.showTrackerPrompt(.whatNow)
        #expect(ui.trackerPromptModel === model)
        #expect(ui.trackerPromptModel?.draft.text == "Typed by hand")
        h.engine.data.live.tracker.prompt = PromptState(kind: .stillOnIt, shownAt: h.clock.now, askTime: h.clock.now)
        ui.showTrackerPrompt(.stillOnIt)
        #expect(ui.trackerPromptModel !== model)
        #expect(ui.trackerPromptModel?.draft.text != "Typed by hand")
        ui.closeTrackerPrompt(.stillOnIt)
    }

    @Test func noteShowsAtTheCenterOutsideTheCornerAndCloses() throws {
        let (h, ui) = setUp()
        let event = CalendarEventInfo(id: "e1", title: "Standup", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 15), calendarID: "c")
        ui.showTrackerNote(.event(event))
        let note = try #require(ui.trackerNotePanel)
        #expect(ui.corner.isEmpty)
        #expect(!note.canBecomeKey)
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
