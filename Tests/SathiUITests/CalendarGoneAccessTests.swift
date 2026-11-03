import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar gone popup without access")
struct CalendarGoneAccessTests {
    private func noAccess() -> EngineHarness {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.access = .denied
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        return h
    }

    @Test func showsTheNoAccessHeadlineAndDetail() throws {
        let sut = try Block.view(CalendarGonePopup(), noAccess())
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockNoAccessHeadline) }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockNoAccessDetail(minutes: 5, title: "Plan")) }
        #expect(!MenuFind.hasText(sut, containing: "is gone"))
        #expect(!MenuFind.hasText(sut, containing: "could not save"))
    }

    @Test func showsTheOpenSettingsButton() throws {
        let sut = try Block.view(CalendarGonePopup(), noAccess())
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.gone.openSettings") }
        #expect(MenuFind.texts(sut).contains(Copywriter.blockOpenSettings))
    }

    @Test func openSettingsOpensTheCalendarPrivacyPane() throws {
        let h = noAccess()
        try Block.tap(Block.view(CalendarGonePopup(), h), id: "block.gone.openSettings")
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        #expect(h.links.opened.map(\.absoluteString) == [url])
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
    }

    @Test func deniedHasNoAllowAccessButton() throws {
        let sut = try Block.view(CalendarGonePopup(), noAccess())
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.allowAccess")) == nil)
        #expect(!MenuFind.texts(sut).contains(Copywriter.blockAllowCalendarAccess))
    }

    @Test func hasNoCalendarListAndNoSaveHere() throws {
        let sut = try Block.view(CalendarGonePopup(), noAccess())
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.saveHere")) == nil)
        for id in ["work", "home"] {
            #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.choice." + id)) == nil)
        }
    }

    @Test func noAccessWithCalendarsStillHidesTheList() throws {
        let h = Block.waiting()
        h.calendarWriter.access = .denied
        h.engine.refreshCalendarAccess()
        let sut = try Block.view(CalendarGonePopup(), h)
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockNoAccessHeadline) }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.saveHere")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.choice.work")) == nil)
    }
}

@MainActor
@Suite("Calendar gone popup without a writable calendar")
struct CalendarGoneNoCalendarTests {
    private func noCalendar() -> EngineHarness {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        return h
    }

    @Test func showsTheNoWritableCalendarLine() throws {
        let sut = try Block.view(CalendarGonePopup(), noCalendar())
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockNoWritableCalendar) }
    }

    @Test func hasNoCalendarRowsAndNoSaveHere() throws {
        let sut = try Block.view(CalendarGonePopup(), noCalendar())
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.saveHere")) == nil)
        for id in ["work", "home"] {
            #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.choice." + id)) == nil)
        }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.openSettings")) == nil)
    }
}

@MainActor
@Suite("Calendar gone popup before access was asked")
struct CalendarGoneNotAskedTests {
    private func notAsked() -> EngineHarness {
        let h = Block.running(.minutes(30), after: 5)
        h.calendarWriter.access = .notAsked
        h.calendarWriter.choices = []
        h.engine.refreshCalendarAccess()
        h.calendarWriter.nextSaveResult = .failed
        h.engine.endBlock()
        return h
    }

    @Test func showsTheAllowAccessButton() throws {
        let h = notAsked()
        #expect(h.engine.calendarAccess == .notAsked)
        let sut = try Block.view(CalendarGonePopup(), h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "block.gone.allowAccess") }
        #expect(MenuFind.texts(sut).contains(Copywriter.blockAllowCalendarAccess))
    }

    @Test func hasNoOpenSettingsButton() throws {
        let sut = try Block.view(CalendarGonePopup(), notAsked())
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "block.gone.openSettings")) == nil)
        #expect(!MenuFind.texts(sut).contains(Copywriter.blockOpenSettings))
    }

    @Test func allowAccessDoesNotOpenSystemSettings() throws {
        let h = notAsked()
        try Block.tap(Block.view(CalendarGonePopup(), h), id: "block.gone.allowAccess")
        #expect(h.links.opened.isEmpty)
        #expect(h.engine.timeBlock?.waitingForCalendar == true)
    }
}
