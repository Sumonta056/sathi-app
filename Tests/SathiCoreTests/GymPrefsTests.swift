import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym prefs")
struct GymPrefsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func defaultsMatchTheDesign() {
        let p = GymPrefs()
        #expect(p.enabled == false)
        #expect(p.intervalMinutes == 60)
        #expect(p.startMinutes == 9 * 60)
        #expect(p.endMinutes == 17 * 60)
        #expect(p.sortedWeekdays == [.monday, .tuesday, .wednesday, .thursday, .friday])
        #expect(p.strictness == .friendly)
        #expect(p.workouts.map(\.name) == ["Neck and shoulder stretch", "Short walk", "10 squats", "Wall push-ups"])
        #expect(p.workouts.map(\.minutes) == [5, 5, 3, 3])
    }

    @Test func limitsMatchTheDesign() {
        #expect(Limits.gymWorkoutCount == 4)
        #expect(Limits.gymDailyGoal == 4)
        #expect(Limits.gymNameMaxLength == 40)
        #expect(Limits.gymWorkoutLengths == [1, 2, 3, 5, 10])
        #expect(Limits.gymIntervalChips == [45, 60, 90])
    }

    @Test func oldPrefsWithoutGymDecodeToDefaults() throws {
        let p = try decode(Prefs.self, #"{"water":{"intervalMinutes":90},"reading":{"enabled":false}}"#)
        #expect(p.gym == GymPrefs())
        #expect(p.water.intervalMinutes == 90)
        #expect(!p.reading.enabled)
    }

    @Test func roundTripKeepsEveryField() throws {
        var p = Prefs()
        p.gym.enabled = true
        p.gym.intervalMinutes = 90
        p.gym.startMinutes = 8 * 60
        p.gym.endMinutes = 18 * 60
        p.gym.weekdays = [.monday, .saturday]
        p.gym.strictness = .persistent
        p.gym.workouts = [
            GymWorkout(name: "Lunges", minutes: 10),
            GymWorkout(name: "Plank", minutes: 2),
            GymWorkout(name: "Jog", minutes: 1),
            GymWorkout(name: "Stairs", minutes: 3)
        ]
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Prefs.self, from: data) == p)
    }

    @Test(arguments: [3, 5])
    func decodingAlwaysGivesFourValidWorkouts(count: Int) throws {
        let rows = (0 ..< count).map { #"{"name":"Move \#($0)","minutes":5}"# }.joined(separator: ",")
        let g = try decode(GymPrefs.self, #"{"workouts":[\#(rows)]}"#)
        #expect(g.workouts.count == 4)
        for i in 0 ..< min(count, 4) {
            #expect(g.workouts[i].name == "Move \(i)")
        }
        if count < 4 { #expect(g.workouts[3] == GymWorkout.defaults[3]) }
    }

    @Test func blankNameFallsBackToTheDefaultOfThatRow() {
        let rows = GymPrefs.cleaned([GymWorkout(name: "  ", minutes: 5)] + Array(GymWorkout.defaults.dropFirst()))
        #expect(rows[0].name == "Neck and shoulder stretch")
    }

    @Test func longNameIsCutToFortyCharacters() {
        let rows = GymPrefs.cleaned([GymWorkout(name: String(repeating: "a", count: 60), minutes: 5)])
        #expect(rows[0].name.count == 40)
        #expect(rows.count == 4)
    }

    @Test func unknownMinutesFallBackToTheDefaultOfThatRow() {
        let rows = GymPrefs.cleaned([GymWorkout(name: "Lunges", minutes: 7)])
        #expect(rows[0] == GymWorkout(name: "Lunges", minutes: 5))
    }

    @Test func workoutIndexWrapsAround() {
        let p = GymPrefs()
        #expect(p.workout(at: 4) == p.workouts[0])
        #expect(p.workout(at: 6) == p.workouts[2])
        #expect(p.workout(at: -1) == p.workouts[3])
    }

    @Test func scheduleKeyChangesWithEveryGymTimingField() {
        let base = Prefs().scheduleKey
        var changes: [(inout Prefs) -> Void] = [
            { $0.gym.enabled = true },
            { $0.gym.intervalMinutes = 90 },
            { $0.gym.startMinutes = 8 * 60 },
            { $0.gym.endMinutes = 18 * 60 },
            { $0.gym.weekdays = [.monday] }
        ]
        for change in changes {
            var p = Prefs()
            change(&p)
            #expect(p.scheduleKey != base)
        }
        changes = [
            { $0.gym.workouts[0].name = "Other" },
            { $0.gym.workouts[1].minutes = 10 }
        ]
        for change in changes {
            var p = Prefs()
            change(&p)
            #expect(p.scheduleKey == base)
        }
    }
}
