import AppKit
import SathiCore
import SwiftUI

extension UIController {
    package func showTrackerPrompt(_ kind: PromptKind) {
        guard let engine, let state = engine.trackerPromptState(kind) else { return }
        let prompt = engine.trackerPrompt
        let model = keptPromptModel(for: prompt) ?? newPromptModel(state)
        let screen = trackerPromptPanel?.screen?.visibleFrame ?? activeScreen?.visibleFrame
        let content = TrackerPromptContent(
            state: state, model: model, visible: screen,
            onDrop: { [weak self] in self?.dropTrackerPrompt() }
        )
        guard let p = replacePromptContent(content) ?? trackerHosting(content).map(presentTrackerCentered) else { return }
        trackerPromptPanel = p
        trackerPromptKind = kind
        trackerPromptShown = prompt
        trackerPromptModel = model
        if engine.trackerPromptTakesKeyboard, !trackerPromptHasKeys {
            trackerPromptHasKeys = true
            takeKeyboard(p)
        }
    }

    private func keptPromptModel(for prompt: PromptState?) -> ActivityPromptModel? {
        guard trackerPromptPanel != nil, prompt != nil, prompt == trackerPromptShown,
              let model = trackerPromptModel, !model.answered else { return nil }
        return model
    }

    private func newPromptModel(_ state: TrackerPromptState) -> ActivityPromptModel {
        let model = ActivityPromptModel(state)
        guard trackerPromptPanel != nil, let old = trackerPromptModel, !old.answered,
              state.kind != .eventAsk, trackerPromptKind != .eventAsk else { return model }
        model.carry(from: old)
        return model
    }

    private func replacePromptContent(_ content: some View) -> NSPanel? {
        guard let p = trackerPromptPanel, let h = p.contentView as? FirstClickHostingView<AnyView>,
              let root = trackerRoot(content) else { return nil }
        h.rootView = root
        p.setContentSize(h.fittingSize)
        return p
    }

    package func closeTrackerPrompt(_ kind: PromptKind) {
        guard trackerPromptKind == kind, let p = trackerPromptPanel else { return }
        trackerPromptPanel = nil
        trackerPromptKind = nil
        trackerPromptShown = nil
        trackerPromptModel = nil
        trackerPromptHasKeys = false
        closeTrackerPanel(p)
        DispatchQueue.main.async { [weak self, weak p] in self?.handBackKeyboard(from: p) }
    }

    func handBackKeyboard(from closed: NSPanel?) {
        guard !trackerPromptHasKeys else { return }
        if NSApp.isActive, NSApp.keyWindow == nil || NSApp.keyWindow === closed { trackerReturnApp?.activate() }
        trackerReturnApp = nil
    }

    package func showTrackerNote(_ note: TrackerNote) {
        closeTrackerNote()
        let state = engine?.trackerNoteState() ?? TrackerNoteState(note: note, calendarTitle: nil, category: nil)
        guard let h = trackerHosting(TrackerNoteView(state: state)) else { return }
        trackerNotePanel = presentTrackerNote(h)
        trackerNoteTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Timing.eventNoteShow * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }
            self?.closeTrackerNote()
        }
    }

    package func closeTrackerNote() {
        trackerNoteTask?.cancel()
        trackerNoteTask = nil
        guard let p = trackerNotePanel else { return }
        trackerNotePanel = nil
        closeTrackerPanel(p)
    }

    package func showTrackerEndOfDay() {
        closeTrackerEndOfDay()
        guard let state = engine?.trackerEndOfDayState(), let h = trackerHosting(EndOfDayView(state: state)) else { return }
        trackerEndOfDayPanel = presentTrackerCentered(h)
    }

    package func closeTrackerEndOfDay() {
        guard let p = trackerEndOfDayPanel else { return }
        trackerEndOfDayPanel = nil
        closeTrackerPanel(p)
    }

    private func takeKeyboard(_ p: NSPanel) {
        let front = NSWorkspace.shared.frontmostApplication
        if trackerReturnApp == nil { trackerReturnApp = front == NSRunningApplication.current ? nil : front }
        NSApp.activate(ignoringOtherApps: true)
        p.makeKey()
    }
}
