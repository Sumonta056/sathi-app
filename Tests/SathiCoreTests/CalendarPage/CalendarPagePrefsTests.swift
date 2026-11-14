import Foundation
import SathiCore
import SathiTestSupport
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
        value.sidePanelShown = false
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

    @Test func oldCalendarPageWithoutSidePanelShowsIt() throws {
        let value = try decode(CalendarPagePrefs.self, #"{"isOn":true,"hiddenCalendarIDs":["a"]}"#)
        #expect(value.sidePanelShown == true)
        #expect(value.isOn == true)
        #expect(CalendarPagePrefs().sidePanelShown == true)
    }

    @Test func savedHiddenSidePanelStaysHidden() throws {
        let value = try decode(CalendarPagePrefs.self, #"{"sidePanelShown":false}"#)
        #expect(value.sidePanelShown == false)
    }

    @Test func sidePanelWrongTypeGivesShownAndKeepsOthers() throws {
        let value = try decode(CalendarPagePrefs.self, #"{"sidePanelShown":"no","isOn":true,"lastCalendarID":"work"}"#)
        #expect(value.sidePanelShown == true)
        #expect(value.isOn == true)
        #expect(value.lastCalendarID == "work")
    }

    @MainActor @Test func settingTheSidePanelSavesIt() {
        let h = EngineHarness()
        h.engine.setCalendarSidePanelShown(false)
        #expect(h.store.prefs.calendarPage.sidePanelShown == false)
        h.engine.setCalendarSidePanelShown(true)
        #expect(h.store.prefs.calendarPage.sidePanelShown == true)
    }

    @Test func calendarPageWrongTypeKeepsOtherPrefs() throws {
        let prefs = try decode(Prefs.self, #"{"calendarPage":3,"general":{"name":"Ana"}}"#)
        #expect(prefs.calendarPage == CalendarPagePrefs())
        #expect(prefs.general.name == "Ana")
    }
}
