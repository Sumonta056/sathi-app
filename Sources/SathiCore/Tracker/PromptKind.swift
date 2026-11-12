import Foundation

package enum PromptKind: String, Codable, CaseIterable, Sendable {
    case whatNow
    case center
    case stillOnIt
    case welcomeBack
    case eventAsk

    package var isCorner: Bool {
        switch self {
        case .whatNow, .stillOnIt, .eventAsk: return true
        case .center, .welcomeBack: return false
        }
    }
}
