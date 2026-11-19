import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar page prefs week days")
struct CalendarPagePrefsWeekDaysTests {
    private func decode(_ json: String) throws -> CalendarPagePrefs {
        try JSONDecoder().decode(CalendarPagePrefs.self, from: Data(json.utf8))
    }

    @Test func theDayCountsAreThreeFourFiveAndSeven() {
        #expect(Limits.calendarWeekDays == [3, 4, 5, 7])
        #expect(Limits.calendarDefaultWeekDays == 7)
    }

    @Test func weekDaysDefaultsToSeven() {
        #expect(CalendarPagePrefs().weekDays == 7)
    }

    @Test func oldCalendarPageWithoutWeekDaysGivesSevenAndKeepsTheRest() throws {
        let value = try decode(#"{"isOn":true,"lastCalendarID":"work","rowMinutes":30,"sidePanelShownWeek":true}"#)
        #expect(value.weekDays == 7)
        #expect(value.isOn == true)
        #expect(value.lastCalendarID == "work")
        #expect(value.rowMinutes == 30)
        #expect(value.sidePanelShownWeek == true)
    }

    @Test(arguments: [3, 4, 5, 7])
    func savedWeekDaysStay(_ days: Int) throws {
        #expect(try decode(#"{"weekDays":\#(days)}"#).weekDays == days)
    }

    @Test(arguments: [#"6"#, #"0"#, #"1"#, #"2"#, #"-3"#, #"8"#, #"14"#, #""3""#, #"3.5"#, #"null"#, #"[3]"#])
    func badWeekDaysGiveSevenAndKeepOthers(_ raw: String) throws {
        let value = try decode(#"{"weekDays":\#(raw),"isOn":true,"rowMinutes":15}"#)
        #expect(value.weekDays == 7)
        #expect(value.isOn == true)
        #expect(value.rowMinutes == 15)
    }

    @Test(arguments: [3, 4, 5, 7])
    func roundTripKeepsWeekDays(_ days: Int) throws {
        var value = CalendarPagePrefs()
        value.isOn = true
        value.rowMinutes = 30
        value.weekDays = days
        let data = try JSONEncoder().encode(value)
        let back = try JSONDecoder().decode(CalendarPagePrefs.self, from: data)
        #expect(back == value)
        #expect(back.weekDays == days)
    }

    @Test func oldPrefsWithoutCalendarPageGiveSevenDays() throws {
        let prefs = try JSONDecoder().decode(Prefs.self, from: Data(#"{"tracker":{"isOn":true}}"#.utf8))
        #expect(prefs.calendarPage.weekDays == 7)
        #expect(prefs.tracker.isOn == true)
    }

    @Test func oldPrefsFileOnDiskLoadsSevenDaysAndKeepsTheRest() throws {
        let base = makeTempFolder()
        let url = base.appendingPathComponent("prefs.json")
        let old = #"{"schemaVersion":1,"value":{"calendarPage":{"isOn":true,"rowMinutes":30,"lastCalendarID":"work"}}}"#
        try writeText(old, to: url)
        let loaded = FileStateStore(base: base).loadPrefs()
        #expect(loaded.calendarPage.weekDays == 7)
        #expect(loaded.calendarPage.isOn == true)
        #expect(loaded.calendarPage.rowMinutes == 30)
        #expect(loaded.calendarPage.lastCalendarID == "work")
    }

    @Test func savedPrefsFileKeepsWeekDaysAfterAFlush() {
        let base = makeTempFolder()
        var prefs = Prefs()
        prefs.calendarPage.weekDays = 4
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(prefs)
        #expect(store.flush())
        #expect(FileStateStore(base: base).loadPrefs().calendarPage.weekDays == 4)
    }
}
