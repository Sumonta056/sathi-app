import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
func quickID(_ h: EngineHarness, _ text: String = "Call mom", _ when: QuickTime = .inMinutes(15)) -> UUID {
    guard case let .added(id) = h.engine.addQuick(text: text, when: when) else { fatalError() }
    return id
}

@MainActor
@Suite("Engine quick fire")
struct EngineQuickFireTests {
    @Test func showsAtDueWithPing() {
        let h = EngineHarness()
        let id = quickID(h)
        h.advance(minutes: 14)
        #expect(!h.presenter.calls.contains(.showQuick(id, .nudge)))
        h.advance(minutes: 1)
        #expect(h.presenter.calls.last == .showQuick(id, .nudge))
        #expect(h.sound.played.last == .ping)
    }

    @Test func showsDuringPause() {
        let h = EngineHarness()
        let id = quickID(h)
        h.engine.pause(hours: 1)
        h.advance(minutes: 15)
        #expect(h.presenter.calls.contains(.showQuick(id, .nudge)))
    }

    @Test func showsOnDayOff() {
        let today = DayKey(day(2026, 3, 4), calendar: .current)
        let h = EngineHarness {
            $0.prefs.water.daysOff = [today]
            $0.prefs.reading.daysOff = [today]
            $0.prefs.meditation.daysOff = [today]
            $0.prefs.gym.daysOff = [today]
        }
        let id = quickID(h)
        h.advance(minutes: 15)
        #expect(h.presenter.calls.contains(.showQuick(id, .nudge)))
    }

    @Test func missedTimeShowsAtLaunch() {
        let item = QuickReminder(text: "Old", due: day(2026, 3, 4, 10, 30), createdAt: day(2026, 3, 4, 9))
        let h = EngineHarness(at: day(2026, 3, 4, 11)) { $0.live.quickReminders = [item] }
        #expect(h.presenter.calls.contains(.showQuick(item.id, .nudge)))
    }

    @Test func twoDueTogetherShowBoth() {
        let h = EngineHarness()
        let a = quickID(h, "A")
        let b = quickID(h, "B")
        h.advance(minutes: 15)
        let shown = h.presenter.calls.filter { if case .showQuick = $0 { return true } else { return false } }
        let order = [a, b].sorted { $0.uuidString < $1.uuidString }
        #expect(shown == order.map { .showQuick($0, .nudge) })
        h.engine.snoozeQuick(a)
        #expect(h.engine.quickActivities[b] != nil)
        #expect(h.engine.quickActivities[a] == nil)
    }

    @Test func doneRemovesAndCloses() {
        let h = EngineHarness()
        let id = quickID(h)
        h.advance(minutes: 15)
        h.engine.quickDone(id)
        #expect(h.presenter.calls.last == .closeQuick(id))
        #expect(h.engine.quickReminders.isEmpty)
        #expect(h.engine.quickActivities.isEmpty)
        #expect(h.history.appended.isEmpty)
    }

    @Test func deleteWhileShowingCloses() {
        let h = EngineHarness()
        let id = quickID(h)
        h.advance(minutes: 15)
        h.engine.removeQuick(id)
        #expect(h.presenter.calls.last == .closeQuick(id))
    }
}
