import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym prefs")
struct GymPrefsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func defaultsAreFourSessionsOfFiveMinutes() {
        let p = GymPrefs()
        #expect(p.enabled == false)
        #expect(p.sessionsPerDay == 4)
        #expect(p.sessionMinutes == 5)
        #expect(p.dailyGoalMinutes == 20)
        #expect(p.startMinutes == 9 * 60)
        #expect(p.endMinutes == 17 * 60)
        #expect(p.sortedWeekdays == [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday])
        #expect(p.strictness == .friendly)
        #expect(p.ideas == ["Neck and shoulder stretch", "Short walk", "10 squats", "Wall push-ups"])
    }

    @Test func defaultIdeasAreTheFourOldWorkoutNames() {
        #expect(GymIdeas.defaults == ["Neck and shoulder stretch", "Short walk", "10 squats", "Wall push-ups"])
    }

    @Test func limitsMatchTheSpec() {
        #expect(Limits.gymSessionCounts == Array(1 ... 8))
        #expect(Limits.gymSessionLengths == [2, 3, 5, 10, 15])
        #expect(Limits.gymIdeasMax == 8)
        #expect(Limits.gymDefaultSessions == 4)
        #expect(Limits.gymDefaultSessionMinutes == 5)
        #expect(Limits.gymLegacyDoneMinutes == 5)
        #expect(Limits.gymNameMaxLength == 40)
    }

    @Test func dailyGoalIsSessionsTimesMinutes() {
        var p = GymPrefs()
        p.sessionsPerDay = 6
        p.sessionMinutes = 10
        #expect(p.dailyGoalMinutes == 60)
    }

    @Test func oldPrefsWithoutGymDecodeToDefaults() throws {
        let p = try decode(Prefs.self, #"{"water":{"intervalMinutes":90},"reading":{"enabled":false}}"#)
        #expect(p.gym == GymPrefs())
        #expect(p.water.intervalMinutes == 90)
        #expect(!p.reading.enabled)
    }

    @Test func oldGymSectionLoadsFourByFiveAndKeepsTheWorkoutNamesAsIdeas() throws {
        let json = #"{"enabled":true,"intervalMinutes":90,"workouts":[{"name":"Lunges","minutes":10},{"name":"Plank","minutes":2}]}"#
        let g = try decode(GymPrefs.self, json)
        #expect(g.sessionsPerDay == 4)
        #expect(g.sessionMinutes == 5)
        #expect(g.ideas == ["Lunges", "Plank"])
        #expect(g.enabled)
    }

    @Test func ideasKeyWinsOverOldWorkouts() throws {
        let json = #"{"sessionsPerDay":3,"sessionMinutes":10,"ideas":["Plank"],"workouts":[{"name":"Lunges","minutes":5}]}"#
        let g = try decode(GymPrefs.self, json)
        #expect(g.ideas == ["Plank"])
        #expect(g.sessionsPerDay == 3)
        #expect(g.sessionMinutes == 10)
    }

    @Test func blankIdeasAreDropped() throws {
        let g = try decode(GymPrefs.self, #"{"ideas":["  ","Plank","","Squats"]}"#)
        #expect(g.ideas == ["Plank", "Squats"])
    }

    @Test(arguments: [#"{"ideas":[]}"#, #"{"ideas":["  ",""]}"#, #"{"workouts":[]}"#, #"{"workouts":[{"name":" ","minutes":5}]}"#])
    func noUsableIdeaLoadsTheDefaults(_ json: String) throws {
        #expect(try decode(GymPrefs.self, json).ideas == GymIdeas.defaults)
    }

    @Test func moreThanEightIdeasKeepTheFirstEight() throws {
        let names = (1 ... 10).map { "\"Move \($0)\"" }.joined(separator: ",")
        let g = try decode(GymPrefs.self, #"{"ideas":[\#(names)]}"#)
        #expect(g.ideas == (1 ... 8).map { "Move \($0)" })
    }

    @Test func ideaNamesAreTrimmedAndCutToFortyCharacters() throws {
        let long = String(repeating: "a", count: 60)
        let g = try decode(GymPrefs.self, #"{"ideas":["  Plank  ","  \#(long) "]}"#)
        #expect(g.ideas == ["Plank", String(repeating: "a", count: 40)])
    }

    @Test(arguments: [(0, 1), (-3, 1), (5, 5), (8, 8), (12, 8)])
    func sessionsPerDayLoadsTheNearestOnTheList(_ row: (Int, Int)) throws {
        #expect(try decode(GymPrefs.self, #"{"sessionsPerDay":\#(row.0)}"#).sessionsPerDay == row.1)
    }

    @Test(arguments: [(4, 3), (1, 2), (3, 3), (7, 5), (8, 10), (12, 10), (13, 15), (60, 15)])
    func sessionMinutesLoadsTheNearestOnTheListAndATiePicksTheSmaller(_ row: (Int, Int)) throws {
        #expect(try decode(GymPrefs.self, #"{"sessionsPerDay":4,"sessionMinutes":\#(row.0)}"#).sessionMinutes == row.1)
    }

    @Test func roundTripKeepsEveryField() throws {
        var p = Prefs()
        p.gym.enabled = true
        p.gym.sessionsPerDay = 6
        p.gym.sessionMinutes = 10
        p.gym.startMinutes = 8 * 60
        p.gym.endMinutes = 18 * 60
        p.gym.weekdays = [.monday, .saturday]
        p.gym.strictness = .persistent
        p.gym.ideas = ["Lunges", "Plank", "Jog"]
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Prefs.self, from: data) == p)
    }

    @Test func blankIdeasAreDroppedOnSave() throws {
        var p = GymPrefs()
        p.ideas = ["Plank", "   ", "Jog"]
        let back = try JSONDecoder().decode(GymPrefs.self, from: JSONEncoder().encode(p))
        #expect(back.ideas == ["Plank", "Jog"])
    }

    @Test func ideaIndexWrapsAround() {
        let p = GymPrefs()
        #expect(p.idea(at: 0) == "Neck and shoulder stretch")
        #expect(p.idea(at: 4) == "Neck and shoulder stretch")
        #expect(p.idea(at: 6) == "10 squats")
        #expect(p.idea(at: -1) == "Wall push-ups")
    }

    @Test func ideaIndexWrapsWithThreeIdeas() {
        var p = GymPrefs()
        p.ideas = ["Lunges", "Plank", "Jog"]
        #expect(p.idea(at: 3) == "Lunges")
        #expect(p.idea(at: 5) == "Jog")
    }

    @Test func ideaOfAnEmptyListIsADefaultIdea() {
        var p = GymPrefs()
        p.ideas = []
        #expect(p.idea(at: 0) == "Neck and shoulder stretch")
    }

    @Test func scheduleKeyChangesWithEveryGymTimingField() {
        let base = Prefs().scheduleKey
        let changes: [(inout Prefs) -> Void] = [
            { $0.gym.enabled = true },
            { $0.gym.sessionsPerDay = 6 },
            { $0.gym.sessionMinutes = 10 },
            { $0.gym.startMinutes = 8 * 60 },
            { $0.gym.endMinutes = 18 * 60 },
            { $0.gym.weekdays = [.monday] }
        ]
        for change in changes {
            var p = Prefs()
            change(&p)
            #expect(p.scheduleKey != base)
        }
    }

    @Test func scheduleKeyIgnoresTheIdeas() {
        var p = Prefs()
        p.gym.ideas = ["Other"]
        #expect(p.scheduleKey == Prefs().scheduleKey)
    }
}
