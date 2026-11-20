import Foundation
import SathiCore
import Testing

@Suite("Tracker prefs decoding")
struct TrackerPrefsDecodingTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func oldPrefsWithoutTheKeyLoadDefaults() throws {
        let p = try prefs(#"{"water":{"intervalMinutes":45},"general":{"name":"Asha"}}"#)
        #expect(p.tracker == TrackerPrefs())
        #expect(p.water.intervalMinutes == 45)
        #expect(p.general.name == "Asha")
    }

    @Test func defaultsMatchTheSpec() {
        let t = TrackerPrefs()
        #expect(!t.isOn)
        #expect(t.startMinutes == 540)
        #expect(t.endMinutes == 1080)
        #expect(t.weekdays == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(t.daysOff.isEmpty)
        #expect(t.askEveryMinutes == 15)
        #expect(t.usualLength == .minutes(30))
        #expect(t.idleMinutes == 30)
        #expect(t.categories.map(\.name) == ["Coding", "Meeting", "Cefalo Meetings", "Review", "Learning", "Email"])
        #expect(t.defaultCalendarID == nil)
        #expect(t.shortcut == KeyShortcut(keyCode: 49, modifiers: [.control, .option, .command], keyName: "Space"))
        #expect(t.endOfDayOn)
        #expect(t.playsSound)
        #expect(!t.readsEvents)
        #expect(!t.quietByDefault)
        #expect(t.readCalendarIDs.isEmpty)
        #expect(t.eventMode == .logAndTell)
        #expect(t.categoryByCalendar.isEmpty)
        #expect(t.eventCategoryByTitle.isEmpty)
        #expect(t.defaultCategory == "Coding")
    }

    @Test func theDefaultShortcutAvoidsTheFinderSearch() throws {
        #expect(KeyShortcut.trackerDefault.modifiers == [.control, .option, .command])
        #expect(KeyShortcut.trackerDefault.keyCode == Limits.spaceKeyCode)
        let json = #"{"shortcut":{"keyCode":49,"modifiers":["option","command"],"keyName":"Space"}}"#
        let t = try JSONDecoder().decode(TrackerPrefs.self, from: Data(json.utf8))
        #expect(t.shortcut == .trackerDefault)
    }

    @Test func theMeetingColorDiffersFromTheMeditationBuddy() {
        let meeting = ActivityCategory.defaults.first { $0.name == "Meeting" }
        #expect(meeting?.colorHex == 0xC9B8FF)
        #expect(meeting?.colorHex != ActivityCategory.buddy(.meditation).colorHex)
    }

    @Test func aBadTrackerValueKeepsOtherSettings() throws {
        let p = try prefs(#"{"tracker":"oops","water":{"intervalMinutes":45}}"#)
        #expect(p.tracker == TrackerPrefs())
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func aBadFieldLoadsItsDefaultAndKeepsTheOthers() throws {
        let p = try prefs(#"{"tracker":{"isOn":"yes","askEveryMinutes":20,"eventMode":"sideways","idleMinutes":7}}"#)
        #expect(!p.tracker.isOn)
        #expect(p.tracker.askEveryMinutes == 20)
        #expect(p.tracker.eventMode == .logAndTell)
        #expect(p.tracker.idleMinutes == 30)
    }

    @Test func badHoursLoadDefaults() throws {
        let p = try prefs(#"{"tracker":{"startMinutes":7,"endMinutes":5000}}"#)
        #expect(p.tracker.startMinutes == 540)
        #expect(p.tracker.endMinutes == 1080)
    }

    @Test func unknownWeekdaysAndBadDaysOffAreDropped() throws {
        let p = try prefs(#"{"tracker":{"weekdays":[2,99],"daysOff":["2026-11-10","nope"]}}"#)
        #expect(p.tracker.weekdays == [.monday])
        #expect(p.tracker.daysOff.map(\.raw) == ["2026-11-10"])
    }

    @Test func aBadCategoryIsDroppedAndTheOthersStay() throws {
        let p = try prefs(#"{"tracker":{"categories":[{"name":"Deep work","colorHex":255},{"name":3}]}}"#)
        #expect(p.tracker.categories == [ActivityCategory(name: "Deep work", colorHex: 255)])
    }

    @Test func savedValuesRoundTrip() throws {
        var t = TrackerPrefs()
        t.isOn = true
        t.startMinutes = 480
        t.weekdays = [.saturday]
        t.usualLength = .open
        t.eventMode = .askFirst
        t.readCalendarIDs = ["work"]
        t.categoryByCalendar = ["work": "Cefalo Meetings"]
        t.eventCategoryByTitle = ["Standup": "Meeting"]
        t.shortcut = KeyShortcut(keyCode: 40, modifiers: [.control, .shift], keyName: "K")
        var p = Prefs()
        p.tracker = t
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.tracker == t)
    }

    @Test func weekdaysAreWrittenInOrder() throws {
        var t = TrackerPrefs()
        t.weekdays = [.friday, .monday, .wednesday]
        let text = try #require(String(data: JSONEncoder().encode(t), encoding: .utf8))
        #expect(text.contains(#""weekdays":[2,4,6]"#))
    }

    @Test func anOldCalendarOnByDefaultKeyIsIgnoredAndTheRestLoads() throws {
        let json = #"{"calendarOnByDefault":true,"askEveryMinutes":30,"defaultCalendarID":"home","isOn":true}"#
        let t = try JSONDecoder().decode(TrackerPrefs.self, from: Data(json.utf8))
        #expect(t.askEveryMinutes == 30)
        #expect(t.defaultCalendarID == "home")
        #expect(t.isOn)
    }

    @Test func theOldCalendarOnByDefaultKeyIsNotWrittenBack() throws {
        let json = #"{"calendarOnByDefault":true,"defaultCalendarID":"home"}"#
        let t = try JSONDecoder().decode(TrackerPrefs.self, from: Data(json.utf8))
        let text = try #require(String(data: JSONEncoder().encode(t), encoding: .utf8))
        #expect(!text.contains("calendarOnByDefault"))
        #expect(text.contains("defaultCalendarID"))
    }
}
