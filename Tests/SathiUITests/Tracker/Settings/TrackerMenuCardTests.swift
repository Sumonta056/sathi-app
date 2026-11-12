import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker menu card")
struct TrackerMenuCardTests {
    private func running(_ h: EngineHarness) -> RunningActivity {
        RunningActivity(text: "Fix login bug", category: "Coding", start: h.clock.now, expectedLength: .minutes(30), askAt: h.clock.now)
    }

    private func card(_ r: RunningActivity?, next: Date? = nil, done: @escaping () -> Void = {}, log: @escaping () -> Void = {}) -> TrackerMenuCard {
        TrackerMenuCard(
            running: r, now: r?.start.addingTimeInterval(52 * 60) ?? Date(timeIntervalSince1970: 0), next: next,
            calendar: .current, accent: Night.tracker, shortcut: "⌃⌥⌘Space", onDone: done, onLog: log
        )
    }

    @Test func runningShowsTextSinceLengthDoneAndSwitch() throws {
        let r = running(EngineHarness())
        let sut = try card(r).inspect()
        _ = try sut.find(text: "Fix login bug")
        _ = try sut.find(text: Copywriter.trackerSinceFor(r.start, now: r.start.addingTimeInterval(52 * 60), calendar: .current))
        _ = try sut.find(button: Copywriter.trackerMenuDone)
        _ = try sut.find(text: Copywriter.trackerSwitchActivity)
        _ = try sut.find(text: "⌃⌥⌘Space")
    }

    @Test func doneAndSwitchCallBack() throws {
        var done = 0
        var logs = 0
        let sut = try card(running(EngineHarness()), done: { done += 1 }, log: { logs += 1 }).inspect()
        try sut.find(button: Copywriter.trackerMenuDone).tap()
        try sut.find(viewWithAccessibilityIdentifier: "menu.tracker.log").button().tap()
        #expect(done == 1)
        #expect(logs == 1)
    }

    @Test func showsTheNextPopupTime() throws {
        let r = running(EngineHarness())
        let next = r.start.addingTimeInterval(30 * 60)
        _ = try card(r, next: next).inspect().find(text: Copywriter.trackerNextAsk(next, calendar: .current))
        _ = try card(nil, next: next).inspect().find(text: Copywriter.trackerNextAsk(next, calendar: .current))
    }

    @Test func nothingRunningShowsNotTrackingAndLogActivity() throws {
        var logs = 0
        let sut = try card(nil, log: { logs += 1 }).inspect()
        _ = try sut.find(text: Copywriter.trackerNotTracking)
        #expect(throws: (any Error).self) { try sut.find(button: Copywriter.trackerMenuDone) }
        try sut.find(viewWithAccessibilityIdentifier: "menu.tracker.log").button().tap()
        #expect(logs == 1)
        _ = try sut.find(text: Copywriter.trackerLogActivity)
    }

    @Test func slotIsEmptyWhenTheTrackerIsOff() throws {
        let sut = try hosted(TrackerMenuSlot(), EngineHarness()).inspect()
        #expect(throws: (any Error).self) { try sut.find(text: Copywriter.trackerNotTracking) }
    }

    @Test func slotShowsTheCardWhenTheTrackerIsOn() throws {
        let h = EngineHarness()
        h.engine.data.prefs.tracker.isOn = true
        _ = try hosted(TrackerMenuSlot(), h).inspect().find(viewWithAccessibilityIdentifier: "menu.tracker.log")
        h.engine.data.live.tracker.running = running(h)
        _ = try hosted(TrackerMenuSlot(), h).inspect().find(text: "Fix login bug")
    }
}
