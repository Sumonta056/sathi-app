import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reading prefs weekdays")
struct ReadingPrefsWeekdaysTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func encodedObject(_ prefs: ReadingPrefs) throws -> [String: Any] {
        let data = try JSONEncoder().encode(prefs)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func defaultsAreEveryDayAndCorner() {
        let r = ReadingPrefs()
        #expect(r.weekdays == Set(Weekday.allCases))
        #expect(r.weekdays.count == 7)
        #expect(r.reminderStyle == .corner)
        #expect(Prefs().reading == r)
    }

    @Test func oldJSONWithoutNewKeysGetsDefaultsAndKeepsOtherFields() throws {
        let json = #"{"enabled":false,"timeMinutes":1290,"sessionMinutes":20,"strictness":"friendly"}"#
        let r = try decode(ReadingPrefs.self, json)
        #expect(r.weekdays == Set(Weekday.allCases))
        #expect(r.reminderStyle == .corner)
        #expect(!r.enabled)
        #expect(r.timeMinutes == 1290)
        #expect(r.sessionMinutes == 20)
        #expect(r.strictness == .friendly)
    }

    @Test func oldPrefsFileKeepsReadingFields() throws {
        let p = try decode(Prefs.self, #"{"reading":{"timeMinutes":1260}}"#)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.reading.weekdays == Set(Weekday.allCases))
        #expect(p.reading.reminderStyle == .corner)
    }

    @Test func emptyWeekdaysArrayDecodesAsEveryDay() throws {
        let r = try decode(ReadingPrefs.self, #"{"weekdays":[]}"#)
        #expect(r.weekdays == Set(Weekday.allCases))
    }

    @Test func newKeysDecode() throws {
        let r = try decode(ReadingPrefs.self, #"{"weekdays":[7,1],"reminderStyle":"focus"}"#)
        #expect(r.weekdays == [.saturday, .sunday])
        #expect(r.reminderStyle == .focus)
    }

    @Test func encodingWritesWeekdaysSortedMondayFirst() throws {
        var r = ReadingPrefs()
        r.weekdays = [.sunday, .friday, .monday, .wednesday]
        let object = try encodedObject(r)
        #expect(object["weekdays"] as? [Int] == [2, 4, 6, 1])
    }

    @Test func encodingWritesTheReminderStyle() throws {
        var r = ReadingPrefs()
        r.reminderStyle = .focus
        #expect(try encodedObject(r)["reminderStyle"] as? String == "focus")
    }

    @Test func sortedWeekdaysStartOnMonday() {
        var r = ReadingPrefs()
        r.weekdays = [.sunday, .saturday, .tuesday]
        #expect(r.sortedWeekdays == [.tuesday, .saturday, .sunday])
    }

    @Test func roundTripKeepsTheSet() throws {
        var p = Prefs()
        p.reading.weekdays = [.sunday, .tuesday, .thursday]
        p.reading.reminderStyle = .focus
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back == p)
        #expect(back.reading.weekdays == [.sunday, .tuesday, .thursday])
    }

    @Test func scheduleKeyChangesWhenAWeekdayIsTurnedOff() {
        let base = Prefs()
        var changed = base
        changed.reading.weekdays.remove(.saturday)
        #expect(changed.scheduleKey != base.scheduleKey)
    }

    @Test func scheduleKeyIgnoresReminderStyle() {
        var p = Prefs()
        let key = p.scheduleKey
        p.reading.reminderStyle = .focus
        #expect(p.scheduleKey == key)
    }
}
