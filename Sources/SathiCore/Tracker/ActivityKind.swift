import Foundation

package enum ActivityKind: String, Codable, CaseIterable, Sendable {
    case work
    case away
    case timeBlock
    case event
    case buddy
}
