import AppKit
import Foundation
import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("SystemPresenceMonitor")
struct PresenceMonitorTests {
    private final class Box { var events: [PresenceEvent] = [] }

    private func make(idle: @escaping () -> TimeInterval = { 0 }) -> (SystemPresenceMonitor, NotificationCenter, NotificationCenter) {
        let workspace = NotificationCenter()
        let distributed = NotificationCenter()
        return (SystemPresenceMonitor(workspaceCenter: workspace, distributedCenter: distributed, idleSeconds: idle), workspace, distributed)
    }

    @Test("lock, unlock, sleep, and wake notifications become presence events")
    func mapsNotifications() {
        let (monitor, workspace, distributed) = make()
        let box = Box()
        monitor.start { box.events.append($0) }
        distributed.post(name: SystemPresenceMonitor.screenLocked, object: nil)
        distributed.post(name: SystemPresenceMonitor.screenUnlocked, object: nil)
        workspace.post(name: NSWorkspace.willSleepNotification, object: nil)
        workspace.post(name: NSWorkspace.didWakeNotification, object: nil)
        #expect(box.events == [.locked, .unlocked, .sleep, .wake])
    }

    @Test("stop removes every observer")
    func stopSilences() {
        let (monitor, workspace, distributed) = make()
        let box = Box()
        monitor.start { box.events.append($0) }
        monitor.stop()
        distributed.post(name: SystemPresenceMonitor.screenLocked, object: nil)
        workspace.post(name: NSWorkspace.willSleepNotification, object: nil)
        #expect(box.events.isEmpty)
    }

    @Test("a second start replaces the first handler")
    func restartReplaces() {
        let (monitor, workspace, _) = make()
        let first = Box()
        let second = Box()
        monitor.start { first.events.append($0) }
        monitor.start { second.events.append($0) }
        workspace.post(name: NSWorkspace.didWakeNotification, object: nil)
        #expect(first.events.isEmpty)
        #expect(second.events == [.wake])
    }

    @Test("idle seconds are read on demand from the injected reader")
    func idleOnDemand() {
        var reads = 0
        let (monitor, _, _) = make(idle: {
            reads += 1
            return 1800
        })
        #expect(reads == 0)
        #expect(monitor.secondsSinceLastInput() == 1800)
        #expect(reads == 1)
    }

    @Test("the system idle reader returns a non-negative number")
    func systemIdle() {
        #expect(PresenceIdleReader.secondsSinceLastInput() >= 0)
    }
}
