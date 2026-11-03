import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine quick snooze")
struct EngineQuickSnoozeTests {
    @Test func snoozeComesBack() {
        let h = EngineHarness { $0.prefs.general.snoozeMinutes = 5 }
        let id = quickID(h)
        h.advance(minutes: 15)
        h.engine.snoozeQuick(id)
        #expect(h.presenter.calls.contains(.showQuickSnoozed("Call mom", day(2026, 3, 4, 10, 20))))
        h.advance(minutes: 5)
        #expect(h.presenter.calls.last == .showQuick(id, .persist))
    }

    @Test func ignoreCountsAsSnooze() {
        let h = EngineHarness { $0.prefs.general.ignoreMinutes = 5 }
        let id = quickID(h)
        h.advance(minutes: 15)
        h.advance(minutes: 5)
        #expect(h.engine.quick(id)?.snoozes == 1)
        #expect(h.presenter.calls.contains(.closeQuick(id)))
    }

    @Test func limitRemovesSnooze() {
        let h = EngineHarness {
            $0.prefs.general.snoozeLimit = 1
            $0.prefs.general.snoozeMinutes = 5
        }
        let id = quickID(h)
        h.advance(minutes: 15)
        h.engine.snoozeQuick(id)
        h.advance(minutes: 5)
        #expect(!h.engine.canSnoozeQuick(id))
        #expect(!h.engine.showsQuickClose(id))
        h.advance(minutes: 60)
        #expect(h.engine.quickActivities[id] != nil)
        #expect(h.engine.quick(id)?.snoozes == 1)
    }

    @Test func snoozeBeforeDueDoesNothing() {
        let h = EngineHarness()
        let id = quickID(h)
        let before = h.presenter.calls.count
        h.engine.snoozeQuick(id)
        #expect(h.engine.quick(id)?.snoozes == 0)
        #expect(h.engine.quick(id)?.snoozedUntil == nil)
        #expect(h.presenter.calls.count == before)
    }

    @Test func closeButtonFollowsPrefs() {
        let h = EngineHarness { $0.prefs.quick.showsCloseButton = false }
        let id = quickID(h)
        h.advance(minutes: 15)
        #expect(!h.engine.showsQuickClose(id))
    }

    @Test func closeButtonShowsByDefault() {
        let h = EngineHarness()
        let id = quickID(h)
        h.advance(minutes: 15)
        #expect(h.engine.showsQuickClose(id))
    }
}

@MainActor
@Suite("Engine quick snooze limit change")
struct EngineQuickLimitChangeTests {
    private func deadline(_ h: EngineHarness, _ id: UUID) -> Date? {
        guard case let .popup(_, d) = h.engine.quickActivities[id] else { return nil }
        return d
    }

    @Test func raisingTheLimitGivesAnOpenPopupItsTimerBack() {
        let h = quickLevelHarness(.persistent, limit: 1)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        #expect(deadline(h, id) == .distantFuture)
        h.engine.data.prefs.general.snoozeLimit = 3
        #expect(deadline(h, id) == h.clock.now.addingTimeInterval(5 * 60))
    }

    @Test func loweringTheLimitStopsTheTimerOfAnOpenPopup() {
        let h = quickLevelHarness(.persistent, limit: 3)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        #expect(deadline(h, id) == h.clock.now.addingTimeInterval(5 * 60))
        h.engine.data.prefs.general.snoozeLimit = 1
        #expect(deadline(h, id) == .distantFuture)
    }
}
