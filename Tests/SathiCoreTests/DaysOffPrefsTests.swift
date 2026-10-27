import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Days off prefs")
struct DaysOffPrefsTests {
    private let everyDay = Set(Weekday.allCases)

    private func keys(_ raws: String...) -> Set<DayKey> {
        Set(raws.compactMap { DayKey(raw: $0) })
    }

    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    private func set(_ id: HabitID, weekdays: Set<Weekday>? = nil, daysOff: Set<DayKey>? = nil, in p: inout Prefs) {
        switch id {
        case .water:
            p.water.weekdays = weekdays ?? p.water.weekdays
            p.water.daysOff = daysOff ?? p.water.daysOff
        case .reading:
            p.reading.weekdays = weekdays ?? p.reading.weekdays
            p.reading.daysOff = daysOff ?? p.reading.daysOff
        case .meditation:
            p.meditation.weekdays = weekdays ?? p.meditation.weekdays
            p.meditation.daysOff = daysOff ?? p.meditation.daysOff
        case .gym:
            p.gym.weekdays = weekdays ?? p.gym.weekdays
            p.gym.daysOff = daysOff ?? p.gym.daysOff
        }
    }

    @Test func limitsMatchTheRules() {
        #expect(Limits.daysOffMaxAhead == 365)
        #expect(Limits.daysOffMax == 100)
    }

    @Test func newFieldsDefaultToEveryDayAndNoDatesOff() {
        #expect(WaterPrefs().weekdays == everyDay)
        #expect(MeditationPrefs().weekdays == everyDay)
        #expect(WaterPrefs().daysOff.isEmpty)
        #expect(ReadingPrefs().daysOff.isEmpty)
        #expect(MeditationPrefs().daysOff.isEmpty)
        #expect(GymPrefs().daysOff.isEmpty)
        for id in HabitID.allCases {
            #expect(Prefs().days(id) == HabitDays(weekdays: everyDay, daysOff: []))
        }
    }

    @Test func gymDefaultIsNowEveryDay() {
        #expect(GymPrefs().weekdays == everyDay)
        #expect(Prefs().days(.gym).weekdays == everyDay)
    }

    @Test func savedGymWeekdaysAreKept() throws {
        let p = try decode(#"{"gym":{"enabled":true,"weekdays":[2,3,4,5,6]}}"#)
        #expect(p.gym.weekdays == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(p.days(.gym).weekdays == [.monday, .tuesday, .wednesday, .thursday, .friday])
    }

    @Test func oldPrefsWithoutNewKeysDecodeToDefaults() throws {
        let p = try decode(#"""
        {"general":{"name":"Asha"},"water":{"intervalMinutes":90},"reading":{"timeMinutes":1260,"weekdays":[2]},
         "meditation":{"enabled":true,"intervalMinutes":45},"gym":{"enabled":true,"intervalMinutes":90}}
        """#)
        #expect(p.water.weekdays == everyDay)
        #expect(p.meditation.weekdays == everyDay)
        #expect(p.reading.weekdays == [.monday])
        #expect(p.gym.weekdays == everyDay)
        for id in HabitID.allCases {
            #expect(p.days(id).daysOff.isEmpty)
        }
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 90)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.meditation.intervalMinutes == 45)
        #expect(p.gym.intervalMinutes == 90)
    }

    @Test(arguments: HabitID.allCases)
    func daysReturnsThatHabitsOwnFields(_ id: HabitID) {
        var p = Prefs()
        set(id, weekdays: [.monday, .sunday], daysOff: keys("2026-11-03"), in: &p)
        #expect(p.days(id) == HabitDays(weekdays: [.monday, .sunday], daysOff: keys("2026-11-03")))
        for other in HabitID.allCases where other != id {
            #expect(p.days(other) == Prefs().days(other))
        }
    }

    @Test(arguments: HabitID.allCases)
    func roundTripKeepsWeekdaysAndDaysOff(_ id: HabitID) throws {
        var p = Prefs()
        set(id, weekdays: [.tuesday, .saturday], daysOff: keys("2026-11-03", "2027-01-01"), in: &p)
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back == p)
        #expect(back.days(id) == HabitDays(weekdays: [.tuesday, .saturday], daysOff: keys("2026-11-03", "2027-01-01")))
    }

    @Test(arguments: HabitID.allCases)
    func daysOffEncodesAsASortedArrayOfStrings(_ id: HabitID) throws {
        var p = Prefs()
        set(id, daysOff: keys("2026-11-10", "2026-10-30", "2027-01-02", "2026-11-03"), in: &p)
        let data = try JSONEncoder().encode(p)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let habit = try #require(object[id.rawValue] as? [String: Any])
        #expect(habit["daysOff"] as? [String] == ["2026-10-30", "2026-11-03", "2026-11-10", "2027-01-02"])
    }

    @Test(arguments: [HabitID.water, .meditation])
    func emptyWeekdaysDecodeAsEveryDay(_ id: HabitID) throws {
        let p = try decode(#"{"general":{"name":"Asha"},"\#(id.rawValue)":{"weekdays":[],"intervalMinutes":45}}"#)
        #expect(p.days(id).weekdays == everyDay)
        #expect(p.general.name == "Asha")
    }

    @Test(arguments: [HabitID.water, .meditation])
    func savedWeekdaysDecode(_ id: HabitID) throws {
        let p = try decode(#"{"\#(id.rawValue)":{"weekdays":[7,1,9]}}"#)
        #expect(p.days(id).weekdays == [.saturday, .sunday])
    }

    @Test(arguments: HabitID.allCases)
    func scheduleKeyChangesWithWeekdaysAndDaysOffOfEveryHabit(_ id: HabitID) {
        let base = Prefs().scheduleKey
        var weekdays = Prefs()
        set(id, weekdays: [.monday], in: &weekdays)
        #expect(weekdays.scheduleKey != base)
        var off = Prefs()
        set(id, daysOff: keys("2026-11-03"), in: &off)
        #expect(off.scheduleKey != base)
        var other = off
        set(id, daysOff: keys("2026-11-04"), in: &other)
        #expect(other.scheduleKey != off.scheduleKey)
    }
}
