import CoreGraphics
import Foundation

package enum PresenceIdleReader {
    private static let anyInput = CGEventType(rawValue: UInt32.max)

    package static func secondsSinceLastInput() -> TimeInterval {
        guard let anyInput else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
