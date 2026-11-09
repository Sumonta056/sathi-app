import Foundation

package enum PresenceEvent: Equatable, Sendable {
    case locked
    case unlocked
    case sleep
    case wake
}

@MainActor
package protocol PresenceMonitor: AnyObject {
    func start(_ onEvent: @escaping @MainActor (PresenceEvent) -> Void)
    func stop()
    func secondsSinceLastInput() -> TimeInterval
}

@MainActor
package final class NoPresenceMonitor: PresenceMonitor {
    package nonisolated init() {}

    package func start(_ onEvent: @escaping @MainActor (PresenceEvent) -> Void) {}
    package func stop() {}
    package func secondsSinceLastInput() -> TimeInterval { 0 }
}
