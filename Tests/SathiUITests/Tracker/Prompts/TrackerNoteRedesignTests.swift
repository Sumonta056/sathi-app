import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker note redesign")
struct TrackerNoteRedesignTests {
    private let twelve = (0 ..< 12).map { ActivityCategory(name: "C\($0)", colorHex: 0x4CC3F5) }
    private let buttons = ["tracker.note.notAttending", "tracker.note.undo", "tracker.note.switch"]

    private func state(_ note: TrackerNote, log: NoteCalls = NoteCalls()) -> TrackerNoteState {
        var s = TrackerNoteState(note: note, calendarTitle: "Work", category: "Meeting")
        s.categories = ActivityCategory.defaults
        s.calendar = Prompt.calendar
        s.actions.pickCategory = { log.calls.append("cat:" + $0) }
        return s
    }

    private func order(_ sut: InspectableView<some BaseViewType>) -> [String] {
        Prompt.ids(sut, prefix: "tracker.note.").filter(buttons.contains)
    }

    @Test func theCategoryIsADropdownWithTheNoteCategory() throws {
        let sut = try TrackerNoteView(state: state(.event(Prompt.event()))).inspect()
        #expect(Prompt.has(sut, "tracker.note.category.menu"))
        let menu = try sut.find(TrackerCategoryMenu.self).actualView()
        #expect(menu.selected == "Meeting")
        #expect(menu.idPrefix == "tracker.note.category.")
        #expect(!menu.allowsNone)
    }

    @Test func aPickInTheListCallsPickCategory() throws {
        let log = NoteCalls()
        let sut = try TrackerNoteView(state: state(.event(Prompt.event()), log: log)).inspect()
        let list = try Prompt.categoryList(sut)
        #expect(!Prompt.has(list, "tracker.note.category.none"))
        try Prompt.tap(list, "tracker.note.category.Learning")
        #expect(log.calls == ["cat:Learning"])
    }

    @Test func twelveCategoriesGiveTwelveRows() throws {
        var s = state(.event(Prompt.event()))
        s.categories = twelve
        let list = try Prompt.categoryList(TrackerNoteView(state: s).inspect())
        #expect(Prompt.ids(list, prefix: "tracker.note.category.") == twelve.map { "tracker.note.category." + $0.name })
    }

    @Test func anEventNoteHasNotAttendingThenUndo() throws {
        let sut = try TrackerNoteView(state: state(.event(Prompt.event()))).inspect()
        #expect(order(sut) == ["tracker.note.notAttending", "tracker.note.undo"])
    }

    @Test func alsoNowHasSwitchThenNotAttendingAndNoCategoryMenu() throws {
        let sut = try TrackerNoteView(state: state(.alsoNow(Prompt.event()))).inspect()
        #expect(order(sut) == ["tracker.note.switch", "tracker.note.notAttending"])
        #expect(sut.findAll(TrackerCategoryMenu.self).isEmpty)
        #expect(!Prompt.has(sut, "tracker.note.category.menu"))
    }

    @Test func anEventNoteSaysWhenItCloses() throws {
        let sut = try TrackerNoteView(state: state(.event(Prompt.event()))).inspect()
        #expect(Prompt.hasText(sut, "Logged now · this note closes in 1 min"))
    }

    @Test func anEndedNoteKeepsTheEndedLine() throws {
        var s = state(.event(Prompt.event()))
        s.endedText = "Write spec"
        let sut = try TrackerNoteView(state: s).inspect()
        let ended = Copywriter.trackerEventEnded("Write spec", at: Prompt.now, calendar: Prompt.calendar)
        #expect(Prompt.hasText(sut, ended))
        #expect(Prompt.has(sut, "tracker.note.category.menu"))
    }
}
