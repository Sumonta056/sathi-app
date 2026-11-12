import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker prompt calendar access")
struct EngineTrackerPromptCalendarAccessTests {
    private let settingsLink = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"

    private func harness(_ access: CalendarAccess) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.access = access
        h.engine.refreshCalendarAccess()
        return h
    }

    @Test(arguments: [CalendarAccess.notAsked, .denied, .allowed])
    func thePromptStateCarriesTheAccessOfTheWriter(_ access: CalendarAccess) throws {
        let h = harness(access)
        let s = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(s.calendarAccess == access)
    }

    @Test func allowAsksMacOSOnceAndReturnsTheFreshCalendars() async throws {
        let h = harness(.notAsked)
        h.calendarWriter.defaultID = "home"
        h.calendarWriter.accessAfterRequest = .allowed
        let s = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(h.calendarWriter.requestCount == 0)
        let info = await s.actions.allowCalendar()
        #expect(h.calendarWriter.requestCount == 1)
        #expect(info == TrackerCalendarInfo(access: .allowed, calendars: h.calendarWriter.choices, defaultID: "home"))
        #expect(info?.calendars.map(\.id) == ["work", "home"])
    }

    @Test func aFreshPromptStateIsAllowedAfterTheGrant() async throws {
        let h = harness(.notAsked)
        h.calendarWriter.accessAfterRequest = .allowed
        let s = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(s.calendarAccess == .notAsked)
        _ = await s.actions.allowCalendar()
        #expect(h.calendarWriter.requestCount == 1)
        let fresh = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(fresh.calendarAccess == .allowed)
        #expect(fresh.calendars.map(\.id) == ["work", "home"])
        #expect(fresh.draft.calendarID == nil)
    }

    @Test func aDeniedAnswerReturnsDeniedWithNoCalendars() async throws {
        let h = harness(.notAsked)
        h.calendarWriter.choices = []
        h.calendarWriter.accessAfterRequest = .denied
        let s = try #require(h.engine.trackerPromptState(.whatNow))
        let info = await s.actions.allowCalendar()
        #expect(h.calendarWriter.requestCount == 1)
        #expect(info == TrackerCalendarInfo(access: .denied, calendars: [], defaultID: nil))
        #expect(h.engine.trackerPromptState(.whatNow)?.calendarAccess == .denied)
    }

    @Test func theDefaultActionReturnsNothing() async {
        let info = await TrackerPromptActions().allowCalendar()
        #expect(info == nil)
    }

    @Test func openCalendarSettingsOpensTheCalendarPrivacyLink() throws {
        let h = harness(.denied)
        let s = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(h.links.opened.isEmpty)
        s.actions.openCalendarSettings()
        #expect(h.links.opened.map(\.absoluteString) == [settingsLink])
    }
}
