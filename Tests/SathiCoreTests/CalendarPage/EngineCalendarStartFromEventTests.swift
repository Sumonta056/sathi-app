import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Calendar page starts an activity from an event")
struct EngineCalendarStartFromEventTests {
    private let standup = meeting(from: wed(10, 30), to: wed(11, 30))

    private func onPage(_ mode: EventMode = .logAndTell, at time: Date = wed(10)) -> EngineHarness {
        let h = EngineHarness.tracker(at: time)
        h.useEvents([standup], mode: mode)
        _ = h.pageDay
        return h
    }

    @Test func activityGetsTheEventTitleAndSourceEventID() {
        let h = onPage(at: wed(10, 40))
        h.engine.data.live.tracker.running = nil
        #expect(h.engine.startActivity(fromEvent: "m1"))
        #expect(h.running?.text == "Standup")
        #expect(h.running?.sourceEventID == "m1")
        #expect(h.running?.kind == .event)
        #expect(h.running?.start == wed(10, 40))
    }

    @Test func runningActivityEndsAtNowLikeATrackerEventLog() {
        let h = onPage(at: wed(9, 30))
        h.start("Spec", minutes: 120)
        h.clock.now = wed(9, 50)
        #expect(h.engine.startActivity(fromEvent: "m1"))
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(9, 50))
        #expect(h.running?.text == "Standup")
        #expect(h.running?.start == wed(9, 50))
    }

    @Test func waitingEventAskForThatEventIsCleared() {
        let h = onPage(.askFirst)
        h.start("Spec", minutes: 120)
        h.advance(minutes: 30)
        #expect(h.promptKind == .eventAsk)
        #expect(h.engine.trackerCalendarRuntime.pendingAsk?.id == "m1")
        _ = h.pageDay
        #expect(h.engine.startActivity(fromEvent: "m1"))
        #expect(h.engine.trackerCalendarRuntime.pendingAsk == nil)
        #expect(h.promptKind == nil)
        h.advance(minutes: 1)
        #expect(h.promptKind != .eventAsk)
        #expect(h.running?.sourceEventID == "m1")
    }

    @Test func waitingAskForAnotherEventIsKept() {
        let other = meeting("m2", "Review", from: wed(12), to: wed(13))
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([standup, other], mode: .askFirst)
        h.advance(minutes: 30)
        #expect(h.engine.trackerCalendarRuntime.pendingAsk?.id == "m1")
        _ = h.pageDay
        #expect(h.engine.startActivity(fromEvent: "m2"))
        #expect(h.engine.trackerCalendarRuntime.pendingAsk?.id == "m1")
        #expect(h.running?.sourceEventID == "m2")
    }

    @Test func unknownEventStartsNothing() {
        let h = onPage(at: wed(9, 30))
        h.start("Spec", minutes: 120)
        #expect(!h.engine.startActivity(fromEvent: "nope"))
        #expect(h.running?.text == "Spec")
        #expect(h.saved.isEmpty)
    }

    @Test func trackerOffStartsNothing() {
        let h = onPage()
        h.engine.data.prefs.tracker.isOn = false
        #expect(!h.engine.startActivity(fromEvent: "m1"))
        #expect(h.running?.sourceEventID == nil)
    }
}
