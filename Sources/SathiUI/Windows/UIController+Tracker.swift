import Foundation
import SathiCore

extension UIController {
    package func showTrackerPrompt(_ kind: PromptKind) {}
    package func closeTrackerPrompt(_ kind: PromptKind) {}
    package func showTrackerNote(_ note: TrackerNote) {}
    package func closeTrackerNote() {}
    package func showTrackerEndOfDay() {}
    package func closeTrackerEndOfDay() {}
}
