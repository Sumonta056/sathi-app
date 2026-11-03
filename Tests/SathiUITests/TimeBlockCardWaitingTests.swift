import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time block card while a block waits")
struct TimeBlockCardWaitingTests {
    private func waiting(_ access: CalendarAccess, choices: [CalendarChoice]? = nil) -> EngineHarness {
        let h = Block.waiting()
        h.calendarWriter.access = access
        if let choices { h.calendarWriter.choices = choices }
        h.engine.refreshCalendarAccess()
        return h
    }

    private func has(_ sut: InspectableView<ViewType.ClassifiedView>, id: String) -> Bool {
        (try? sut.find(viewWithAccessibilityIdentifier: id)) != nil
    }

    @Test func usesTheSharedWaitingSaveAction() throws {
        let sut = try Block.card(waiting(.allowed))
        #expect(sut.findAll(WaitingSaveAction.self).count == 1)
    }

    @Test func theCalendarGonePopupUsesTheSharedWaitingSaveAction() throws {
        let sut = try Block.view(CalendarGonePopup(), waiting(.allowed))
        #expect(sut.findAll(WaitingSaveAction.self).count == 1)
    }

    @Test func deniedShowsOpenSettingsAndNoList() throws {
        let sut = try Block.card(waiting(.denied))
        #expect(has(sut, id: "block.openSettings"))
        #expect(!has(sut, id: "block.allowAccess"))
        #expect(!has(sut, id: "block.saveHere"))
        for id in ["work", "home"] {
            #expect(!has(sut, id: "block.choice." + id))
        }
    }

    @Test func deniedOpenSettingsOpensTheCalendarPrivacyPane() throws {
        let h = waiting(.denied)
        try Block.tap(Block.card(h), id: "block.openSettings")
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        #expect(h.links.opened.map(\.absoluteString) == [url])
    }

    @Test func notAskedShowsAllowAccess() throws {
        let sut = try Block.card(waiting(.notAsked))
        #expect(has(sut, id: "block.allowAccess"))
        #expect(MenuFind.texts(sut).contains(Copywriter.blockAllowCalendarAccess))
        #expect(!has(sut, id: "block.openSettings"))
        #expect(!has(sut, id: "block.saveHere"))
    }

    @Test func allowedWithoutCalendarsSaysSoWithNoSaveHere() throws {
        let sut = try Block.card(waiting(.allowed, choices: []))
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockNoWritableCalendar) }
        #expect(!has(sut, id: "block.saveHere"))
        #expect(!has(sut, id: "block.openSettings"))
    }

    @Test func allowedWithCalendarsKeepsTheListAndSaveHere() throws {
        let sut = try Block.card(waiting(.allowed))
        #expect(has(sut, id: "block.saveHere"))
        #expect(has(sut, id: "block.choice.work"))
        #expect(has(sut, id: "block.choice.home"))
        #expect(!has(sut, id: "block.openSettings"))
        #expect(!has(sut, id: "block.allowAccess"))
    }
}
