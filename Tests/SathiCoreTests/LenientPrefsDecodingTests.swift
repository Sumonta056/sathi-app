import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Lenient prefs decoding")
struct LenientPrefsDecodingTests {
    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func unknownWeekdayIsDroppedAndOtherPrefsStay() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"water":{"intervalMinutes":90},"reading":{"timeMinutes":1260,"weekdays":[2,9]}}"#)
        #expect(p.reading.weekdays == [.monday])
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 90)
    }

    @Test func emptyWeekdaysDecodeAsEveryDay() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"reading":{"weekdays":[]}}"#)
        #expect(p.reading.weekdays == Set(Weekday.allCases))
        #expect(p.general.name == "Asha")
    }

    @Test func onlyUnknownWeekdaysDecodeAsEveryDay() throws {
        let p = try decode(#"{"reading":{"weekdays":[0,9]}}"#)
        #expect(p.reading.weekdays == Set(Weekday.allCases))
    }

    @Test func unknownReminderStyleBecomesCorner() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"reading":{"reminderStyle":"silent","timeMinutes":1260}}"#)
        #expect(p.reading.reminderStyle == .corner)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.general.name == "Asha")
    }

    @Test func oldSlotsSetTheGoalFromKnownSlotsAndUnknownStyleBecomesBox() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"meditation":{"enabled":true,"slots":["morning","night"],"style":"square"}}"#)
        #expect(p.meditation.dailyGoalMinutes == MeditationPrefs().sessionMinutes)
        #expect(p.meditation.style == .box)
        #expect(p.meditation.enabled)
        #expect(p.general.name == "Asha")
    }

    @Test func oldSlotsNeverResetTheNewMeditationFields() throws {
        let p = try decode(#"{"meditation":{"slots":["night"],"intervalMinutes":90,"startMinutes":480}}"#)
        #expect(p.meditation.intervalMinutes == 90)
        #expect(p.meditation.startMinutes == 480)
    }
}
