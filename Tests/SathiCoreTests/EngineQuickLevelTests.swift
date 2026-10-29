import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
func quickLevelHarness(_ strictness: Strictness, limit: Int? = nil) -> EngineHarness {
    EngineHarness {
        $0.prefs.quick.strictness = strictness
        $0.prefs.general.snoozeLimit = limit
        $0.prefs.general.snoozeMinutes = 5
        $0.prefs.general.ignoreMinutes = 5
    }
}

@MainActor
func quickShows(_ h: EngineHarness) -> [SpyPresenter.Call] {
    h.presenter.calls.filter {
        switch $0 {
        case .showQuick, .showQuickLock: return true
        default: return false
        }
    }
}

@MainActor
func snoozeQuickAndReturn(_ h: EngineHarness, _ id: UUID) {
    h.engine.snoozeQuick(id)
    h.advance(minutes: 5)
}

@MainActor
@Suite("Engine quick levels")
struct EngineQuickLevelTests {
    @Test func gentleStaysNudge() {
        let h = quickLevelHarness(.friendly)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        snoozeQuickAndReturn(h, id)
        snoozeQuickAndReturn(h, id)
        #expect(quickShows(h) == Array(repeating: .showQuick(id, .nudge), count: 4))
    }

    @Test func nudgyPersistsAfterOne() {
        let h = quickLevelHarness(.persistent)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        #expect(quickShows(h) == [.showQuick(id, .nudge), .showQuick(id, .persist)])
    }

    @Test func strictLocksAfterTwo() {
        let h = quickLevelHarness(.strict)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        snoozeQuickAndReturn(h, id)
        #expect(quickShows(h) == [.showQuick(id, .nudge), .showQuick(id, .persist), .showQuickLock(id)])
        #expect(h.sound.played.last == .sosumi)
        #expect(h.engine.quickActivities[id] == .lock)
    }

    @Test func strictLimitOneNeverLocks() {
        let h = quickLevelHarness(.strict, limit: 1)
        let id = quickID(h)
        h.advance(minutes: 15)
        snoozeQuickAndReturn(h, id)
        h.advance(minutes: 60)
        #expect(quickShows(h) == [.showQuick(id, .nudge), .showQuick(id, .persist)])
    }

    @Test func restartKeepsLevel() {
        var item = QuickReminder(text: "Old", due: day(2026, 3, 4, 9, 30), createdAt: day(2026, 3, 4, 9))
        item.snoozes = 2
        let h = EngineHarness(at: day(2026, 3, 4, 11)) {
            $0.prefs.quick.strictness = .strict
            $0.prefs.general.snoozeLimit = nil
            $0.live.quickReminders = [item]
        }
        #expect(quickShows(h) == [.showQuickLock(item.id)])
    }
}
