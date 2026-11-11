import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine activity prompt keyboard")
struct EnginePromptKeyboardTests {
    @Test func noPromptTakesNoKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        #expect(h.promptKind == nil)
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func aScheduledWhatNowTakesNoKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        #expect(h.promptKind == .whatNow)
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func stillOnItTakesNoKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.advance(minutes: 30)
        #expect(h.promptKind == .stillOnIt)
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func welcomeBackTakesNoKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.unlocked)
        #expect(h.promptKind == .welcomeBack)
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func anEventAskTakesNoKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))], mode: .askFirst)
        h.start("Spec", minutes: 30)
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        #expect(!h.engine.trackerPromptTakesKeyboard)
    }

    @Test func theShortcutPromptTakesTheKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.openTrackerPanel()
        #expect(h.promptKind == .center)
        #expect(h.engine.trackerPromptTakesKeyboard)
    }

    @Test func doneTakesTheKeyboard() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 30)
        h.engine.doneActivity()
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPromptTakesKeyboard)
    }
}
