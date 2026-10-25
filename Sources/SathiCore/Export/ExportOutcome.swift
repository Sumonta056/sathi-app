import Foundation

package enum ExportOutcome: Equatable, Sendable {
    case saved(URL)
    case cancelled
    case failed
}
