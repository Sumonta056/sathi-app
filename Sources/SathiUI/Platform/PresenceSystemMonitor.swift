import AppKit
import SathiCore

@MainActor
package final class SystemPresenceMonitor: PresenceMonitor {
    package static let screenLocked = Notification.Name("com.apple.screenIsLocked")
    package static let screenUnlocked = Notification.Name("com.apple.screenIsUnlocked")

    private let workspaceCenter: NotificationCenter
    private let distributedCenter: NotificationCenter
    private let idleSeconds: () -> TimeInterval
    private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    package init(
        workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        distributedCenter: NotificationCenter = DistributedNotificationCenter.default(),
        idleSeconds: @escaping () -> TimeInterval = PresenceIdleReader.secondsSinceLastInput
    ) {
        self.workspaceCenter = workspaceCenter
        self.distributedCenter = distributedCenter
        self.idleSeconds = idleSeconds
    }

    package func start(_ onEvent: @escaping @MainActor (PresenceEvent) -> Void) {
        stop()
        let map: [(NotificationCenter, Notification.Name, PresenceEvent)] = [
            (workspaceCenter, NSWorkspace.willSleepNotification, .sleep),
            (workspaceCenter, NSWorkspace.didWakeNotification, .wake),
            (distributedCenter, Self.screenLocked, .locked),
            (distributedCenter, Self.screenUnlocked, .unlocked)
        ]
        for (center, name, event) in map {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { onEvent(event) }
            }
            tokens.append((center, token))
        }
    }

    package func stop() {
        for entry in tokens {
            entry.center.removeObserver(entry.token)
        }
        tokens = []
    }

    package func secondsSinceLastInput() -> TimeInterval { idleSeconds() }
}
