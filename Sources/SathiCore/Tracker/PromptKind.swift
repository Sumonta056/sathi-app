import Foundation

package enum PromptKind: String, Codable, CaseIterable, Sendable {
    case whatNow
    case center
    case stillOnIt
    case welcomeBack
    case eventAsk
    case todoDue
}
