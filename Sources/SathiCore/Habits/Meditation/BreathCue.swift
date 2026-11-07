import Foundation

package enum BreathCue: String, CaseIterable, Sendable {
    case begin, inhale, hold, exhale, rest, wellDone

    package init(_ phase: BreathPhase) {
        switch phase {
        case .inhale: self = .inhale
        case .hold: self = .hold
        case .exhale: self = .exhale
        case .rest: self = .rest
        }
    }
}
