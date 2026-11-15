import Foundation

package enum PromptReason: CaseIterable, Equatable, Sendable {
    case ask
    case shortcut
    case ends
    case back
    case event
    case todo

    package init(_ kind: PromptKind) {
        switch kind {
        case .whatNow: self = .ask
        case .center: self = .shortcut
        case .stillOnIt: self = .ends
        case .welcomeBack: self = .back
        case .eventAsk: self = .event
        case .todoDue: self = .todo
        }
    }
}
