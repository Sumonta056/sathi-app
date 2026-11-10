import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker note view")
struct TrackerNoteViewTests {
    private func state(_ note: TrackerNote, log: NoteCalls = NoteCalls()) -> TrackerNoteState {
        var s = TrackerNoteState(note: note, calendarTitle: "Work", category: "Meeting")
        s.categories = ActivityCategory.defaults
        s.calendar = Prompt.calendar
        s.actions.undo = { log.calls.append("undo") }
        s.actions.notAttending = { log.calls.append("notAttending") }
        s.actions.pickCategory = { log.calls.append("cat:" + $0) }
        s.actions.switchToEvent = { log.calls.append("switch") }
        return s
    }

    @Test func eventNoteShowsTitleSpanAndActions() throws {
        let log = NoteCalls()
        let sut = try TrackerNoteView(state: state(.event(Prompt.event()), log: log)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Standup") }
        try Prompt.tap(sut, "tracker.note.undo")
        try Prompt.tap(sut, "tracker.note.notAttending")
        try Prompt.tap(sut, "tracker.note.category.Review")
        #expect(log.calls == ["undo", "notAttending", "cat:Review"])
    }

    @Test func alsoNowHasSwitchAndNoUndo() throws {
        let log = NoteCalls()
        let sut = try TrackerNoteView(state: state(.alsoNow(Prompt.event()), log: log)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Also now: Standup") }
        try Prompt.tap(sut, "tracker.note.switch")
        #expect(log.calls == ["switch"])
        #expect(!Prompt.has(sut, "tracker.note.undo"))
    }
}

final class NoteCalls {
    var calls: [String] = []
}
