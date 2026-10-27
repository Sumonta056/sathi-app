import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reminder interval")
struct ReminderIntervalTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func everyIntervalHabitSharesOneListOfEightChips() {
        #expect(Limits.intervalChips == [15, 30, 45, 60, 75, 90, 105, 120])
    }

    @Test(arguments: [(10, 15), (0, 15), (-30, 15), (15, 15), (45, 45), (50, 45), (53, 60), (100, 105), (120, 120), (180, 120), (240, 120)])
    func nearestPicksTheClosestChip(_ row: (Int, Int)) {
        #expect(ReminderInterval.nearest(row.0) == row.1)
    }

    @Test(arguments: [15, 30, 45, 60, 75, 90, 105, 120])
    func everyChipIsItsOwnNearest(_ minutes: Int) {
        #expect(ReminderInterval.nearest(minutes) == minutes)
    }

    @Test(arguments: [(180, 120), (10, 15), (50, 45), (53, 60), (45, 45)])
    func waterLoadsTheNearestChip(_ row: (Int, Int)) throws {
        #expect(try decode(WaterPrefs.self, #"{"intervalMinutes":\#(row.0)}"#).intervalMinutes == row.1)
    }

    @Test(arguments: [(180, 120), (10, 15), (50, 45), (90, 90)])
    func meditationLoadsTheNearestChip(_ row: (Int, Int)) throws {
        #expect(try decode(MeditationPrefs.self, #"{"intervalMinutes":\#(row.0)}"#).intervalMinutes == row.1)
    }

    @Test(arguments: [(180, 120), (10, 15), (45, 45), (53, 60)])
    func gymLoadsTheNearestChip(_ row: (Int, Int)) throws {
        #expect(try decode(GymPrefs.self, #"{"intervalMinutes":\#(row.0)}"#).intervalMinutes == row.1)
    }

    @Test func anOffListIntervalKeepsTheOtherSettings() throws {
        let json = #"{"general":{"name":"Asha"},"water":{"intervalMinutes":240,"dailyGoalGlasses":10},"gym":{"enabled":true,"intervalMinutes":7}}"#
        let p = try decode(Prefs.self, json)
        #expect(p.water.intervalMinutes == 120)
        #expect(p.water.dailyGoalGlasses == 10)
        #expect(p.gym.intervalMinutes == 15)
        #expect(p.gym.enabled)
        #expect(p.general.name == "Asha")
    }

    @Test func aChipIntervalSurvivesARoundTrip() throws {
        var p = Prefs()
        p.water.intervalMinutes = 75
        p.meditation.intervalMinutes = 15
        p.gym.intervalMinutes = 105
        #expect(try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p)) == p)
    }
}
