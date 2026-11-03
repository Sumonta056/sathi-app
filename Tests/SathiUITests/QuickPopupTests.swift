import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick popup")
struct QuickPopupTests {
    private func setup(limit: Int? = nil, level: Level = .nudge) -> (EngineHarness, UUID) {
        let item = Quick.item("Call mom", minutes: 5)
        let h = EngineHarness(at: Quick.now) {
            $0.live.quickReminders = [item]
            $0.prefs.general.snoozeLimit = limit
            $0.prefs.general.snoozeMinutes = 5
            $0.prefs.general.ignoreMinutes = 5
        }
        h.advance(minutes: 5)
        if level == .persist { h.advance(minutes: 5) }
        return (h, item.id)
    }

    private func popup(_ h: EngineHarness, _ id: UUID, _ level: Level) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(QuickPopup(id: id, level: level), h).inspect()
    }

    @Test func popupShowsCopy() throws {
        let (h, id) = setup()
        let sut = try popup(h, id, .nudge)
        #expect(throws: Never.self) { try sut.find(text: "QUICK REMINDER · " + Quick.clock(day(2026, 3, 4, 10, 5))) }
        #expect(throws: Never.self) { try sut.find(text: "Call mom") }
        #expect(throws: Never.self) { try sut.find(text: "You set this at " + Quick.clock(Quick.now) + ".") }
        #expect(throws: Never.self) { try sut.find(button: "Done") }
        #expect(throws: Never.self) { try sut.find(button: "In 5 min") }
    }

    @Test func popupDoneCallsEngine() throws {
        let (h, id) = setup()
        try popup(h, id, .nudge).find(button: "Done").tap()
        #expect(h.engine.quickReminders.isEmpty)
    }

    @Test func popupSnoozeCallsEngine() throws {
        let (h, id) = setup()
        try popup(h, id, .nudge).find(button: "In 5 min").tap()
        #expect(h.engine.quick(id)?.snoozes == 1)
    }

    @Test func closeShownAtNudge() throws {
        let (h, id) = setup()
        #expect(throws: Never.self) { try popup(h, id, .nudge).find(viewWithAccessibilityLabel: "Dismiss") }
    }

    @Test func closeHiddenAtPersist() throws {
        let (h, id) = setup(level: .persist)
        let sut = try popup(h, id, .persist)
        #expect(throws: (any Error).self) { try sut.find(viewWithAccessibilityLabel: "Dismiss") }
        #expect(throws: Never.self) { try sut.find(button: "Done") }
    }

    @Test func limitShowsOnlyDone() throws {
        let (h, id) = setup(limit: 0)
        let sut = try popup(h, id, .nudge)
        #expect(throws: (any Error).self) { try sut.find(button: "In 5 min") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.quickNoSnooze) }
        #expect(throws: Never.self) { try sut.find(button: "Done") }
    }

    @Test func snoozedNoteShowsComeBack() throws {
        let h = Quick.harness()
        let until = day(2026, 3, 4, 10, 5)
        let sut = try hosted(QuickSnoozedNote(text: "Call mom", until: until), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "“Call mom” comes back at " + Quick.clock(until)) }
    }
}
