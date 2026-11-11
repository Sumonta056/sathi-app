import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker presenter fix round")
struct TrackerPresenterFixTests {
    private func setUp(_ configure: (EngineHarness) -> Void = { _ in }) -> (EngineHarness, UIController) {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        configure(h)
        let ui = UIController()
        ui.engine = h.engine
        return (h, ui)
    }

    @Test func aResumeWhatNowTheUserDidNotAskForLeavesTheKeyboard() {
        let at = day(2026, 3, 4, 10)
        let prompt = PromptState(kind: .whatNow, shownAt: at, askTime: at, switchFrom: at, resume: ActivityDraft(text: "Spec"))
        #expect(!UIController.trackerPromptTakesKeyboard(prompt, byUser: false))
        #expect(UIController.trackerPromptTakesKeyboard(prompt, byUser: true))
    }

    @Test func escOnTheWhatNowPanelLeavesTheSkipToThePopup() throws {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        let p = try #require(ui.trackerPromptPanel)
        p.cancelOperation(nil)
        #expect(h.engine.trackerPrompt?.kind == .whatNow)
        ui.closeTrackerPrompt(.whatNow)
    }

    @Test func escInWhatNowSkipsAtThePickedSwitchTime() throws {
        let calls = PromptCalls()
        let times = [Prompt.now.addingTimeInterval(-600), Prompt.now]
        let s = Prompt.state(.whatNow, calls: calls) { $0.switchTimes = times }
        try WhatNowPopup(state: s).inspect().find(ViewType.VStack.self).callOnExitCommand()
        #expect(calls.skipped == [Prompt.now])
    }

    @Test func aCornerPromptWatchesItsSizeOnce() {
        let (h, ui) = setUp { $0.engine.tick() }
        ui.showTrackerPrompt(.whatNow)
        #expect(ui.trackerResizeTokens.count == 1)
        ui.closeTrackerPrompt(.whatNow)
        #expect(ui.trackerResizeTokens.isEmpty)
        withExtendedLifetime(h) {}
    }

    @Test func aCenteredPromptKeepsItsCenterWhenItGrows() throws {
        let (h, ui) = setUp()
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        let p = try #require(ui.trackerPromptPanel)
        let center = NSPoint(x: p.frame.midX, y: p.frame.midY)
        p.setContentSize(NSSize(width: p.frame.width, height: p.frame.height + 80))
        #expect(abs(p.frame.midX - center.x) < 1)
        #expect(abs(p.frame.midY - center.y) < 1)
        ui.closeTrackerPrompt(.center)
    }

    @Test func swappingPromptsKeepsTheAppToGiveTheKeyboardBackTo() throws {
        let (h, ui) = setUp()
        let other = try #require(NSWorkspace.shared.runningApplications.first { $0 != NSRunningApplication.current })
        h.engine.openTrackerPanel()
        ui.showTrackerPrompt(.center)
        ui.trackerReturnApp = other
        ui.closeTrackerPrompt(.center)
        ui.showTrackerPrompt(.center)
        #expect(ui.trackerReturnApp == other)
        ui.handBackKeyboard(from: nil)
        #expect(ui.trackerReturnApp == other)
        ui.trackerReturnApp = nil
        ui.closeTrackerPrompt(.center)
    }
}
