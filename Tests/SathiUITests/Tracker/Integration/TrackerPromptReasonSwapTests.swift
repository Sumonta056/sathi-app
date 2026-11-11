import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Tracker prompt reason swap")
struct TrackerPromptReasonSwapTests {
    private func setUp() -> (EngineHarness, UIController) {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        let ui = UIController()
        ui.engine = h.engine
        return (h, ui)
    }

    private func swap(_ h: EngineHarness, _ ui: UIController, to kind: PromptKind) {
        h.engine.data.live.tracker.prompt = PromptState(kind: kind, shownAt: h.clock.now, askTime: h.clock.now)
        ui.showTrackerPrompt(kind)
    }

    private func textFields(in view: NSView?) -> [NSTextField] {
        guard let view else { return [] }
        let own = (view as? NSTextField).map { [$0] } ?? []
        return own + view.subviews.flatMap { textFields(in: $0) }.filter(\.isEditable)
    }

    private func editingFields(_ ui: UIController) -> [NSTextField] {
        let content = ui.trackerPromptPanel?.contentView
        content?.layoutSubtreeIfNeeded()
        return textFields(in: content)
    }

    @Test func typedTextAndCategoryMoveToTheNewReason() throws {
        let (h, ui) = setUp()
        swap(h, ui, to: .whatNow)
        let old = try #require(ui.trackerPromptModel)
        old.draft.text = "Half typed"
        old.draft.category = "Review"
        swap(h, ui, to: .center)
        let model = try #require(ui.trackerPromptModel)
        #expect(model !== old)
        #expect(model.draft.text == "Half typed")
        #expect(model.draft.category == "Review")
        ui.closeTrackerPrompt(.center)
    }

    @Test func anEventReasonBringsItsOwnText() throws {
        let (h, ui) = setUp()
        swap(h, ui, to: .whatNow)
        try #require(ui.trackerPromptModel).draft.text = "Half typed"
        swap(h, ui, to: .eventAsk)
        #expect(ui.trackerPromptModel?.draft.text != "Half typed")
        ui.closeTrackerPrompt(.eventAsk)
    }

    @Test func anAnsweredPromptCarriesNothing() throws {
        let (h, ui) = setUp()
        swap(h, ui, to: .whatNow)
        let old = try #require(ui.trackerPromptModel)
        old.draft.text = "Done one"
        old.answered = true
        swap(h, ui, to: .center)
        #expect(ui.trackerPromptModel?.draft.text == "")
        ui.closeTrackerPrompt(.center)
    }

    @Test func theFieldStartsEditingAfterAnEventPrompt() {
        let (h, ui) = setUp()
        swap(h, ui, to: .eventAsk)
        #expect(editingFields(ui).isEmpty)
        swap(h, ui, to: .center)
        #expect(!editingFields(ui).isEmpty)
        ui.closeTrackerPrompt(.center)
    }
}
