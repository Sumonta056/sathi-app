import Foundation
import SathiCore

extension SpyPresenter {
    package enum TrackerCall: Equatable {
        case showPrompt(PromptKind), closePrompt(PromptKind)
        case showNote(TrackerNote), closeNote
        case showEndOfDay, closeEndOfDay
    }

    package var shownPrompts: [PromptKind] {
        trackerCalls.compactMap { if case let .showPrompt(kind) = $0 { kind } else { nil } }
    }

    package func showTrackerPrompt(_ kind: PromptKind) { trackerCalls.append(.showPrompt(kind)) }
    package func closeTrackerPrompt(_ kind: PromptKind) { trackerCalls.append(.closePrompt(kind)) }
    package func showTrackerNote(_ note: TrackerNote) { trackerCalls.append(.showNote(note)) }
    package func closeTrackerNote() { trackerCalls.append(.closeNote) }
    package func showTrackerEndOfDay() { trackerCalls.append(.showEndOfDay) }
    package func closeTrackerEndOfDay() { trackerCalls.append(.closeEndOfDay) }
}
