import Foundation

package enum Presentation: Equatable, Sendable {
    case bubble(Level)
    case lock
}

package enum EscalationPolicy {
    package static func presentation(for strictness: Strictness, snoozes: Int) -> Presentation {
        switch strictness {
        case .friendly:
            return .bubble(.nudge)
        case .persistent:
            return .bubble(snoozes == 0 ? .nudge : .persist)
        case .strict:
            if snoozes == 0 { return .bubble(.nudge) }
            if snoozes == 1 { return .bubble(.persist) }
            return .lock
        }
    }

    package static func lockIsNext(_ strictness: Strictness, snoozes: Int) -> Bool {
        strictness == .strict && snoozes >= 1
    }
}
