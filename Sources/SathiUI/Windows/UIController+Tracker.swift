import AppKit
import SathiCore
import SwiftUI

extension UIController {
    package func showTrackerPrompt(_ kind: PromptKind) {
        if let shown = trackerPromptKind { closeTrackerPrompt(shown) }
        guard let engine, let state = engine.trackerPromptState(kind),
              let h = trackerHosting(TrackerPromptContent(state: state)) else { return }
        let takesKeys = Self.trackerPromptTakesKeyboard(engine.trackerPrompt, byUser: engine.trackerPromptByUser)
        let p = kind.isCorner ? placeTrackerCorner(h, onCancel: Self.cancelAction(state)) : presentTrackerCentered(h)
        trackerPromptPanel = p
        trackerPromptKind = kind
        trackerPromptHasKeys = takesKeys
        if takesKeys { takeKeyboard(p) }
    }

    package func closeTrackerPrompt(_ kind: PromptKind) {
        guard trackerPromptKind == kind, let p = trackerPromptPanel else { return }
        trackerPromptPanel = nil
        trackerPromptKind = nil
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
        trackerNotePanel = placeTrackerCorner(h, onCancel: {})
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

    static func trackerPromptTakesKeyboard(_ prompt: PromptState?, byUser: Bool) -> Bool {
        guard let prompt else { return false }
        switch prompt.kind {
        case .center, .welcomeBack: return true
        case .whatNow: return byUser && (prompt.switchFrom != nil || prompt.resume != nil)
        case .stillOnIt, .eventAsk: return false
        }
    }

    private static func cancelAction(_ state: TrackerPromptState) -> () -> Void {
        switch state.kind {
        case .center, .welcomeBack: return { state.actions.close() }
        case .whatNow: return {}
        case .stillOnIt, .eventAsk: return {}
        }
    }

    private func takeKeyboard(_ p: NSPanel) {
        let front = NSWorkspace.shared.frontmostApplication
        if trackerReturnApp == nil { trackerReturnApp = front == NSRunningApplication.current ? nil : front }
        NSApp.activate(ignoringOtherApps: true)
        p.makeKey()
    }
}
