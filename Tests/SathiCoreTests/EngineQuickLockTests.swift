import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
private func lockHarness(limit: Int?, quickDue: Date, quickSnoozes: Int) -> (EngineHarness, UUID) {
    var item = QuickReminder(text: "Call mom", due: quickDue, createdAt: day(2026, 3, 4, 14))
    item.snoozes = quickSnoozes
    let h = EngineHarness(at: day(2026, 3, 4, 15)) {
        $0.prefs.quick.strictness = .strict
        $0.prefs.water.strictness = .strict
        $0.prefs.general.snoozeLimit = limit
        $0.prefs.general.snoozeMinutes = 5
        $0.prefs.general.ignoreMinutes = 5
        $0.live.lastWaterDone = day(2026, 3, 4, 14, 59)
        $0.live.quickReminders = [item]
    }
    return (h, item.id)
}

@MainActor
private func lockWater(_ h: EngineHarness) {
    h.showReminder(.water)
    for _ in 0 ..< 2 {
        h.engine.snooze(.water)
        h.advance(minutes: 5)
    }
}

@MainActor
@Suite("Engine quick lock")
struct EngineQuickLockTests {
    @Test func snoozeOnLockDoesNothing() {
        let (h, id) = lockHarness(limit: nil, quickDue: day(2026, 3, 4, 15), quickSnoozes: 2)
        let before = h.presenter.calls.count
        h.engine.snoozeQuick(id)
        guard case .lock = h.engine.quickActivities[id] else {
            Issue.record("lock should stay")
            return
        }
        #expect(h.engine.quick(id)?.snoozes == 2)
        #expect(h.presenter.calls.count == before)
        #expect(!h.presenter.calls.contains(.closeLock))
    }

    @Test func lockDoneCloses() {
        let (h, id) = lockHarness(limit: nil, quickDue: day(2026, 3, 4, 15), quickSnoozes: 2)
        h.engine.quickDone(id)
        #expect(h.presenter.calls.last == .closeLock)
        #expect(h.engine.quickReminders.isEmpty)
        #expect(h.engine.quickActivities.isEmpty)
    }

    @Test func deleteWhileLockedClosesLock() {
        let (h, id) = lockHarness(limit: nil, quickDue: day(2026, 3, 4, 15), quickSnoozes: 2)
        h.engine.removeQuick(id)
        #expect(h.presenter.calls.last == .closeLock)
        #expect(h.engine.quickActivities[id] == nil)
    }

    @Test func quickWaitsForBuddyLock() {
        let (h, id) = lockHarness(limit: nil, quickDue: day(2026, 3, 4, 15, 8), quickSnoozes: 2)
        lockWater(h)
        #expect(h.engine.phase(.water) == .lock)
        #expect(quickShows(h) == [.showQuick(id, .persist)])
        #expect(!h.presenter.calls.contains(.showQuickLock(id)))
    }

    @Test func quickLocksWhenBuddyLockEnds() {
        let (h, id) = lockHarness(limit: 2, quickDue: day(2026, 3, 4, 15, 8), quickSnoozes: 2)
        lockWater(h)
        #expect(quickShows(h) == [.showQuick(id, .persist)])
        h.engine.emergencySkip(.water)
        h.engine.tick()
        #expect(quickShows(h) == [.showQuick(id, .persist), .showQuickLock(id)])
        #expect(h.presenter.calls.contains(.closeQuick(id)))
        #expect(h.sound.played.last == .sosumi)
    }

    @Test func buddyWaitsForQuickLock() {
        let (h, id) = lockHarness(limit: nil, quickDue: day(2026, 3, 4, 15), quickSnoozes: 2)
        lockWater(h)
        #expect(h.engine.quickActivities[id] == .lock)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        #expect(!h.presenter.calls.contains(.showLock(.water)))
    }

    @Test func buddyLocksWhenQuickLockEnds() {
        let (h, id) = lockHarness(limit: 2, quickDue: day(2026, 3, 4, 15), quickSnoozes: 2)
        lockWater(h)
        #expect(!h.presenter.calls.contains(.showLock(.water)))
        h.engine.quickDone(id)
        h.engine.tick()
        #expect(h.presenter.calls.last == .showLock(.water))
    }
}
