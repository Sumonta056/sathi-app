import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym workout decoding")
struct GymWorkoutDecodingTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    private func load(secondRow: String) throws -> Prefs {
        let json = """
        {"schemaVersion":1,"value":{\
        "general":{"name":"Asha"},\
        "water":{"intervalMinutes":45},\
        "gym":{"enabled":true,"intervalMinutes":90,"workouts":[\
        {"name":"Lunges","minutes":10},\(secondRow),{"name":"Plank","minutes":2},{"name":"Jog","minutes":1}]}\
        }}
        """
        try writeText(json, to: prefsURL)
        return FileStateStore(base: base, delay: 3600).loadPrefs()
    }

    private func expectRestKept(_ p: Prefs) {
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 45)
        #expect(p.gym.enabled)
        #expect(p.gym.intervalMinutes == 90)
        #expect(p.gym.workouts[0] == GymWorkout(name: "Lunges", minutes: 10))
        #expect(p.gym.workouts[2] == GymWorkout(name: "Plank", minutes: 2))
        #expect(p.gym.workouts[3] == GymWorkout(name: "Jog", minutes: 1))
    }

    @Test func rowWithoutMinutesGetsThatRowsDefaultMinutes() throws {
        let p = try load(secondRow: #"{"name":"Stairs"}"#)
        #expect(p.gym.workouts[1] == GymWorkout(name: "Stairs", minutes: GymWorkout.defaults[1].minutes))
        expectRestKept(p)
    }

    @Test func rowWithANumberNameGetsThatRowsDefaultName() throws {
        let p = try load(secondRow: #"{"name":42,"minutes":3}"#)
        #expect(p.gym.workouts[1] == GymWorkout(name: GymWorkout.defaults[1].name, minutes: 3))
        expectRestKept(p)
    }

    @Test func cleanedWithNoRowsGivesTheDefaults() {
        #expect(GymPrefs.cleaned([]) == GymWorkout.defaults)
    }

    @Test func cleanedWithFourGoodRowsKeepsThem() {
        let rows = [
            GymWorkout(name: "Lunges", minutes: 10),
            GymWorkout(name: "Plank", minutes: 2),
            GymWorkout(name: "Jog", minutes: 1),
            GymWorkout(name: "Stairs", minutes: 3)
        ]
        #expect(GymPrefs.cleaned(rows) == rows)
    }
}
