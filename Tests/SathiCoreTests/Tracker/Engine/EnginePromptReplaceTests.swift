import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine activity prompt replace")
struct EnginePromptReplaceTests {
    @Test func theShortcutOverAShownPromptReplacesItWithoutClosingIt() {
        let h = EngineHarness.tracker(at: wed(10))
        #expect(h.promptKind == .whatNow)
        let before = h.presenter.trackerCalls.count
        h.engine.openTrackerPanel()
        #expect(Array(h.presenter.trackerCalls.dropFirst(before)) == [.showPrompt(.center)])
    }

    @Test func doneOverAShownStillOnItReplacesItWithoutClosingIt() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start(minutes: 15)
        h.advance(minutes: 15)
        #expect(h.promptKind == .stillOnIt)
        let before = h.presenter.trackerCalls.count
        h.engine.doneActivity()
        #expect(h.promptKind == .whatNow)
        #expect(!h.presenter.trackerCalls.dropFirst(before).contains(.closePrompt(.stillOnIt)))
        #expect(h.presenter.trackerCalls.last == .showPrompt(.whatNow))
    }

    @Test func answeringThePromptStillClosesIt() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        #expect(h.presenter.trackerCalls.last == .closePrompt(.whatNow))
    }
}
