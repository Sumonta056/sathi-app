import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time block settings access")
struct TimeBlockSettingsAccessTests {
    @Test func allowedShowsAllowedAndNoButtons() throws {
        let sut = try BlockSettings.page(BlockSettings.harness())
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsAllowed) }
        #expect(!BlockSettings.has(sut, "settings.block.access.open"))
        #expect(!BlockSettings.has(sut, "settings.block.access.allow"))
    }

    @Test func deniedShowsNotAllowedAndTheSettingsButton() throws {
        let sut = try BlockSettings.page(BlockSettings.harness(access: .denied))
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsNotAllowed) }
        #expect(BlockSettings.has(sut, "settings.block.access.open"))
        #expect(!BlockSettings.has(sut, "settings.block.access.allow"))
        #expect(Find.lacks(sut, text: Copywriter.blockSettingsAllowed))
    }

    @Test func openSystemSettingsOpensTheCalendarPrivacyPane() throws {
        let h = BlockSettings.harness(access: .denied)
        try BlockSettings.tap(BlockSettings.page(h), "settings.block.access.open")
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        #expect(h.links.opened.map(\.absoluteString) == [url])
    }

    @Test func notAskedShowsNotAskedYetAndAllowAccess() throws {
        let sut = try BlockSettings.page(BlockSettings.harness(access: .notAsked))
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsNotAsked) }
        #expect(BlockSettings.has(sut, "settings.block.access.allow"))
        #expect(!BlockSettings.has(sut, "settings.block.access.open"))
    }

    @Test func allowAccessAsksMacOSAndShowsAllowedAfterGrant() async throws {
        let h = BlockSettings.harness(access: .notAsked)
        h.calendarWriter.accessAfterRequest = .allowed
        try BlockSettings.tap(BlockSettings.page(h), "settings.block.access.allow")
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        #expect(h.calendarWriter.requestCount == 1)
        #expect(h.engine.calendarAccess == .allowed)
        let sut = try BlockSettings.page(h)
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsAllowed) }
    }

    @Test func deniedHidesTheCalendarListAndShowsAHint() throws {
        let sut = try BlockSettings.page(BlockSettings.harness(access: .denied))
        for choice in ["work", "home"] {
            #expect(!BlockSettings.has(sut, "settings.block.calendar.\(choice)"))
        }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsNeedsAccess) }
    }

    @Test func notAskedHidesTheCalendarList() throws {
        let sut = try BlockSettings.page(BlockSettings.harness(access: .notAsked))
        #expect(!BlockSettings.has(sut, "settings.block.calendar.work"))
    }
}
