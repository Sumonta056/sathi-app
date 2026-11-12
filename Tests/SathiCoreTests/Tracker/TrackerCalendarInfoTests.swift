@testable import SathiCore
import Testing

@Suite("Tracker calendar info")
struct TrackerCalendarInfoTests {
    private let work = CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0)
    private let home = CalendarChoice(id: "home", title: "Home", account: "iCloud", colorHex: 0)

    @Test func allowedTicksTheDefaultCalendar() {
        let info = TrackerCalendarInfo(access: .allowed, calendars: [work, home], defaultID: "home")
        #expect(info.tickID == "home")
    }

    @Test func aMissingDefaultTicksTheFirstCalendar() {
        let info = TrackerCalendarInfo(access: .allowed, calendars: [work, home], defaultID: "gone")
        #expect(info.tickID == "work")
    }

    @Test func noCalendarsTickNothing() {
        #expect(TrackerCalendarInfo(access: .allowed, calendars: [], defaultID: nil).tickID == nil)
    }

    @Test(arguments: [CalendarAccess.denied, .notAsked])
    func noAccessTicksNothing(_ access: CalendarAccess) {
        #expect(TrackerCalendarInfo(access: access, calendars: [work], defaultID: "work").tickID == nil)
    }
}
