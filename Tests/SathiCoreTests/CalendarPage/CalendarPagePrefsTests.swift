import Foundation
import SathiCore
import Testing

@Suite("Calendar page prefs")
struct CalendarPagePrefsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func oldPrefsWithoutCalendarPageLoadDefaults() throws {
        let prefs = try decode(Prefs.self, #"{"tracker":{"isOn":true}}"#)
        #expect(prefs.calendarPage == CalendarPagePrefs())
        #expect(prefs.tracker.isOn == true)
    }

    @Test func roundTripKeepsEveryField() throws {
        var value = CalendarPagePrefs()
        value.isOn = true
        value.hiddenCalendarIDs = ["a", "b"]
        value.lastCalendarID = "work"
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(CalendarPagePrefs.self, from: data) == value)
    }

    @Test func badHiddenElementIsDropped() throws {
        let value = try decode(CalendarPagePrefs.self, #"{"hiddenCalendarIDs":["a",5],"isOn":true}"#)
        #expect(value.hiddenCalendarIDs == ["a"])
        #expect(value.isOn == true)
    }

    @Test func hiddenNotAListGivesEmptyAndKeepsOthers() throws {
        let value = try decode(CalendarPagePrefs.self, #"{"hiddenCalendarIDs":"x","isOn":true}"#)
        #expect(value.hiddenCalendarIDs.isEmpty)
        #expect(value.isOn == true)
    }

    @Test func calendarPageWrongTypeKeepsOtherPrefs() throws {
        let prefs = try decode(Prefs.self, #"{"calendarPage":3,"general":{"name":"Ana"}}"#)
        #expect(prefs.calendarPage == CalendarPagePrefs())
        #expect(prefs.general.name == "Ana")
    }
}
