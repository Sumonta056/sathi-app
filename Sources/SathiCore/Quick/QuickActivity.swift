import Foundation

package enum QuickActivity: Equatable, Sendable {
    case popup(Level, ignoreDeadline: Date)
    case lock
}
