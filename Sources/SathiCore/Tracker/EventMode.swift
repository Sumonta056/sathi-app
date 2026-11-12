import Foundation

package enum EventMode: String, Codable, CaseIterable, Sendable {
    case logAndTell
    case askFirst
}
