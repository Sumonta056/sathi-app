import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker menu row")
struct TrackerMenuRowTests {
    private func running(_ h: EngineHarness) -> RunningActivity {
        RunningActivity(text: "Fix login bug", category: "Coding", start: h.clock.now, expectedLength: .minutes(30), askAt: h.clock.now)
    }

    @Test func rowShowsTextSinceAndDone() throws {
        let h = EngineHarness()
        let r = running(h)
        let sut = try TrackerMenuRow(running: r, calendar: .current, accent: Color(hex: 0x4CC3F5), onDone: {}).inspect()
        _ = try sut.find(text: "Fix login bug")
        _ = try sut.find(text: Copywriter.trackerSince(r.start, calendar: .current))
        _ = try sut.find(button: Copywriter.trackerMenuDone)
    }

    @Test func doneButtonCallsBack() throws {
        var done = 0
        let h = EngineHarness()
        let sut = try TrackerMenuRow(running: running(h), calendar: .current, accent: Night.tracker, onDone: { done += 1 }).inspect()
        try sut.find(button: Copywriter.trackerMenuDone).tap()
        #expect(done == 1)
    }

    @Test func slotIsEmptyWhenNothingRuns() throws {
        let h = EngineHarness()
        let sut = try hosted(TrackerMenuSlot(), h).inspect()
        #expect(throws: (any Error).self) { try sut.find(button: Copywriter.trackerMenuDone) }
    }

    @Test func slotShowsTheRunningActivity() throws {
        let h = EngineHarness()
        h.engine.data.live.tracker.running = running(h)
        let sut = try hosted(TrackerMenuSlot(), h).inspect()
        _ = try sut.find(text: "Fix login bug")
    }

    @Test func logButtonCallsBack() throws {
        var taps = 0
        let sut = try TrackerLogButton(onTap: { taps += 1 }).inspect()
        try sut.find(button: Copywriter.trackerLogActivity).tap()
        #expect(taps == 1)
    }

    @Test func logButtonLabelIsLogActivity() throws {
        let sut = try hosted(TrackerLogActivityButton(), EngineHarness()).inspect()
        _ = try sut.find(text: Copywriter.trackerLogActivity)
    }
}
