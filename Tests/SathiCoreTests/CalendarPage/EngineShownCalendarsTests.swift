import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine shown calendars")
struct EngineShownCalendarsTests {
    func harness() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = [
            CalendarEventInfo(id: "w", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work"),
            CalendarEventInfo(id: "h", title: "Dinner", start: day(2026, 3, 4, 19), end: day(2026, 3, 4, 20), calendarID: "home")
        ]
        return h
    }

    func titles(_ h: EngineHarness) -> [String] {
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: .day, calendar: h.engine.calendar)
        return h.engine.calendarPage(range).blocks.map(\.title).sorted()
    }

    @Test func everyReadableCalendarIsShownAtFirst() {
        let h = harness()
        #expect(h.engine.shownCalendarIDs == ["work", "home"])
        #expect(titles(h) == ["Dinner", "Standup"])
    }

    @Test func hidingHomeKeepsTrackerCalendars() {
        let h = harness()
        h.engine.data.prefs.tracker.readCalendarIDs = ["home"]
        h.engine.setCalendarShown("home", false)
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs == ["home"])
        #expect(h.store.prefs.calendarPage.hiddenCalendarIDs == ["home"])
        #expect(titles(h) == ["Standup"])
        #expect(h.engine.data.prefs.tracker.readCalendarIDs == ["home"])
        h.engine.setCalendarShown("home", true)
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs.isEmpty)
    }

    @Test func trackerCalendarsDoNotChangeHidden() {
        let h = harness()
        h.engine.setCalendarShown("work", false)
        h.engine.data.prefs.tracker.readCalendarIDs = ["work", "home"]
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs == ["work"])
    }

    @Test func newReadableCalendarShows() {
        let h = harness()
        h.engine.setCalendarShown("home", false)
        h.calendarWriter.readable = h.calendarWriter.choices + [CalendarChoice(id: "new", title: "New", account: "iCloud", colorHex: 0x123456)]
        #expect(h.engine.shownCalendarIDs == ["work", "new"])
    }

    @Test func groupsByAccount() {
        let h = harness()
        h.engine.setCalendarShown("home", false)
        let groups = h.engine.shownCalendarGroups()
        #expect(groups.map(\.account) == ["Gmail", "iCloud"])
        #expect(groups.map { $0.calendars.map(\.choice.title) } == [["Gmail Work"], ["Home"]])
        #expect(groups.map { $0.calendars.map(\.isShown) } == [[true], [false]])
    }

    @Test func pageSwitchSaves() {
        let h = harness()
        h.engine.setCalendarPageOn(true)
        #expect(h.store.prefs.calendarPage.isOn)
        h.engine.setCalendarPageOn(false)
        #expect(!h.store.prefs.calendarPage.isOn)
    }
}
