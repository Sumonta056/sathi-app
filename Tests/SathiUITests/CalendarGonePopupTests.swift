import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar gone popup")
struct CalendarGonePopupTests {
    @Test func goneCalendarShowsTheGoneHeadline() throws {
        let sut = try Block.view(CalendarGonePopup(), Block.goneHarness())
        #expect(throws: Never.self) { try sut.find(text: "TIME BLOCK · NOT SAVED YET") }
        #expect(MenuFind.texts(sut).contains { $0.hasPrefix("Your calendar “") && $0.hasSuffix("” is gone") })
        #expect(!MenuFind.hasText(sut, containing: "could not save"))
    }

    @Test func existingCalendarShowsTheFailedHeadline() throws {
        let sut = try Block.view(CalendarGonePopup(), Block.waiting())
        #expect(throws: Never.self) { try sut.find(text: "Sathi could not save to “Gmail Work”") }
        #expect(!MenuFind.hasText(sut, containing: "is gone"))
    }

    @Test func showsTheMinutesAndTitleToSave() throws {
        let sut = try Block.view(CalendarGonePopup(), Block.waiting())
        #expect(throws: Never.self) { try sut.find(text: "Choose one to save 5 min on Plan.") }
    }

    @Test func listsEveryWritableCalendarWithItsAccount() throws {
        let sut = try Block.view(CalendarGonePopup(), Block.waiting())
        for id in ["work", "home"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.gone.choice." + id) }
        }
        let texts = MenuFind.texts(sut)
        #expect(texts.contains("Gmail Work"))
        #expect(texts.contains("Home"))
        #expect(texts.contains("Gmail"))
        #expect(texts.contains("iCloud"))
    }

    @Test func goneListHasOnlyTheRemainingCalendars() throws {
        let sut = try Block.view(CalendarGonePopup(), Block.goneHarness())
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.choice.work")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.gone.choice.home") }
    }

    @Test func saveHereWritesToTheDefaultSelection() throws {
        let h = Block.waiting()
        h.calendarWriter.nextSaveResult = nil
        try Block.tap(Block.view(CalendarGonePopup(), h), id: "block.gone.saveHere")
        #expect(h.calendarWriter.saved.last?.calendarID == "work")
        #expect(h.engine.timeBlock == nil)
        #expect(h.presenter.calls.last == .closeBlockCalendarGone)
    }

    @Test func savingToAnotherCalendarUsesTheChosenRow() throws {
        let h = Block.waiting()
        h.calendarWriter.nextSaveResult = nil
        let sut = try Block.view(CalendarGonePopup(), h)
        try Block.tap(sut, id: "block.gone.choice.home")
        try Block.tap(sut, id: "block.gone.saveHere")
        #expect(h.calendarWriter.saved.last?.calendarID == "home")
        #expect(h.calendarWriter.saved.last?.title == "Plan")
        #expect(h.engine.timeBlock == nil)
    }

    @Test func aGoneCalendarSavesToTheFirstRemainingOne() throws {
        let h = Block.goneHarness()
        h.calendarWriter.nextSaveResult = nil
        try Block.tap(Block.view(CalendarGonePopup(), h), id: "block.gone.saveHere")
        #expect(h.calendarWriter.saved.last?.calendarID == "home")
        #expect(h.engine.timeBlock == nil)
    }
}

@MainActor
@Suite("Calendar gone popup with stale choices")
struct CalendarGoneStaleTests {
    private func deletedWork() -> EngineHarness {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        return h
    }

    @Test func aCalendarDeletedOutsideSathiShowsTheGoneHeadline() throws {
        let sut = try Block.view(CalendarGonePopup(), deletedWork())
        #expect(throws: Never.self) { try sut.find(text: "Your calendar “Gmail Work” is gone") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.choice.work")) == nil)
    }

    @Test func saveHereUsesARemainingCalendar() throws {
        let h = deletedWork()
        h.calendarWriter.nextSaveResult = nil
        try Block.tap(Block.view(CalendarGonePopup(), h), id: "block.gone.saveHere")
        #expect(h.calendarWriter.saved.last?.calendarID == "home")
        #expect(h.engine.timeBlock == nil)
    }
}
