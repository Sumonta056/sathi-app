import Foundation
import SathiCore

@MainActor
package final class FakePresenceMonitor: PresenceMonitor {
    package var idleSeconds: TimeInterval = 0
    package private(set) var starts = 0
    package private(set) var stops = 0
    package private(set) var idleReads = 0
    private var listener: (@MainActor (PresenceEvent) -> Void)?

    package init() {}

    package var isListening: Bool { listener != nil }

    package func start(_ onEvent: @escaping @MainActor (PresenceEvent) -> Void) {
        listener = onEvent
        starts += 1
    }

    package func stop() {
        listener = nil
        stops += 1
    }

    package func secondsSinceLastInput() -> TimeInterval {
        idleReads += 1
        return idleSeconds
    }

    package func send(_ event: PresenceEvent) { listener?(event) }
}

@MainActor
package final class SpyHotkeyRegistrar: HotkeyRegistrar {
    package var result = true
    package private(set) var registered: [KeyShortcut] = []
    package private(set) var unregisters = 0
    private var onPress: (@MainActor () -> Void)?

    package init() {}

    @discardableResult
    package func register(_ shortcut: KeyShortcut, onPress: @escaping @MainActor () -> Void) -> Bool {
        registered.append(shortcut)
        if result { self.onPress = onPress }
        return result
    }

    package func unregister() {
        onPress = nil
        unregisters += 1
    }

    package func press() { onPress?() }
}
