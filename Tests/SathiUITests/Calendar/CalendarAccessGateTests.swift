import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar access gate")
struct CalendarAccessGateTests {
    private func gate(_ access: CalendarAccess) throws -> (EngineHarness, InspectableView<ViewType.ClassifiedView>) {
        let h = EngineHarness()
        h.calendarWriter.access = access
        h.engine.refreshCalendarAccess()
        return try (h, hosted(CalendarAccessGate(), h).inspect())
    }

    @Test func notAskedShowsAllowCalendarAccess() throws {
        let (_, sut) = try gate(.notAsked)
        #expect(throws: Never.self) { try sut.find(text: "Allow calendar access") }
        #expect(Find.lacks(sut, text: "Open System Settings"))
    }

    @Test func deniedShowsOpenSystemSettingsAndOpensThePrivacyPane() throws {
        let (h, sut) = try gate(.denied)
        #expect(throws: Never.self) { try sut.find(text: "Open System Settings") }
        #expect(Find.lacks(sut, text: "Allow calendar access"))
        try Find.button(sut, holding: "Open System Settings").tap()
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        #expect(h.links.opened.map(\.absoluteString) == [url])
    }

    @Test(arguments: [CalendarAccess.notAsked, .denied])
    func bothStatesShowTheTitle(_ access: CalendarAccess) throws {
        let (_, sut) = try gate(access)
        #expect(throws: Never.self) { try sut.find(text: "Your calendar, in Sathi") }
    }

    @Test func notAskedSaysSathiNeedsAccess() throws {
        let (_, sut) = try gate(.notAsked)
        #expect(throws: Never.self) { try sut.find(text: "Sathi needs calendar access to show your events.") }
        #expect(Find.lacks(sut, text: "Calendar access is off. Turn it on in System Settings."))
    }

    @Test func deniedSaysAccessIsOff() throws {
        let (_, sut) = try gate(.denied)
        #expect(throws: Never.self) { try sut.find(text: "Calendar access is off. Turn it on in System Settings.") }
        #expect(Find.lacks(sut, text: "Sathi needs calendar access to show your events."))
    }

    @Test(arguments: [CalendarAccess.notAsked, .denied])
    func withoutAccessThePageHasNoHeader(_ access: CalendarAccess) throws {
        let h = EngineHarness()
        h.calendarWriter.access = access
        h.engine.refreshCalendarAccess()
        let sut = try hosted(CalendarPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarAccessGate.self) }
        #expect((try? sut.find(CalendarPageHeader.self)) == nil)
    }

    @Test func withAccessThePageHasTheHeaderAndNoGate() throws {
        let h = EngineHarness()
        h.calendarWriter.access = .allowed
        h.engine.refreshCalendarAccess()
        let sut = try hosted(CalendarPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarPageHeader.self) }
        #expect((try? sut.find(CalendarAccessGate.self)) == nil)
    }

    @Test func notAskedTapAsksForAccess() async throws {
        let (h, sut) = try gate(.notAsked)
        try Find.button(sut, holding: "Allow calendar access").tap()
        await Task.yield()
        #expect(h.calendarWriter.access != .denied)
    }
}
