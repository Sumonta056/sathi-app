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
        value.rowMinutes = 15
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

    @Test func rowMinutesDefaultsToOneHour() throws {
        #expect(CalendarPagePrefs().rowMinutes == 60)
        #expect(try decode(CalendarPagePrefs.self, #"{"isOn":true}"#).rowMinutes == 60)
        #expect(Limits.calendarRowMinutes == [60, 30, 15])
    }

    @Test(arguments: [60, 30, 15])
    func savedRowMinutesStay(_ minutes: Int) throws {
        #expect(try decode(CalendarPagePrefs.self, #"{"rowMinutes":\#(minutes)}"#).rowMinutes == minutes)
    }

    @Test(arguments: [#"45"#, #"0"#, #"-15"#, #""x""#, #"null"#])
    func badRowMinutesGiveOneHourAndKeepOthers(_ raw: String) throws {
        let value = try decode(CalendarPagePrefs.self, #"{"rowMinutes":\#(raw),"isOn":true}"#)
        #expect(value.rowMinutes == 60)
        #expect(value.isOn == true)
    }

    @MainActor @Test func settingRowMinutesSavesOnlyAKnownStep() {
        let h = EngineHarness()
        h.engine.setCalendarRowMinutes(15)
        #expect(h.store.prefs.calendarPage.rowMinutes == 15)
        h.engine.setCalendarRowMinutes(45)
        #expect(h.store.prefs.calendarPage.rowMinutes == 15)
    }

    @Test func calendarPageWrongTypeKeepsOtherPrefs() throws {
        let prefs = try decode(Prefs.self, #"{"calendarPage":3,"general":{"name":"Ana"}}"#)
        #expect(prefs.calendarPage == CalendarPagePrefs())
        #expect(prefs.general.name == "Ana")
    }
}
