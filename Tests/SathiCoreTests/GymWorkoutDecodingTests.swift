import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym legacy workouts decoding")
struct GymWorkoutDecodingTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    private func load(gym: String) throws -> Prefs {
        let json = """
        {"schemaVersion":1,"value":{\
        "general":{"name":"Asha"},\
        "water":{"intervalMinutes":45},\
        "gym":\(gym)\
        }}
        """
        try writeText(json, to: prefsURL)
        return FileStateStore(base: base, delay: 3600).loadPrefs()
    }

    private func oldGym(secondRow: String) -> String {
        #"{"enabled":true,"intervalMinutes":90,"workouts":[{"name":"Lunges","minutes":10},\#(secondRow),{"name":"Plank","minutes":2}]}"#
    }

    private func expectRestKept(_ p: Prefs) {
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 45)
        #expect(p.gym.enabled)
    }

    @Test func oldFileLoadsFourByFiveWithTheWorkoutNamesAsIdeas() throws {
        let p = try load(gym: oldGym(secondRow: #"{"name":"Stairs","minutes":3}"#))
        #expect(p.gym.sessionsPerDay == 4)
        #expect(p.gym.sessionMinutes == 5)
        #expect(p.gym.dailyGoalMinutes == 20)
        #expect(p.gym.ideas == ["Lunges", "Stairs", "Plank"])
        expectRestKept(p)
    }

    @Test func oldRowWithoutMinutesKeepsItsName() throws {
        let p = try load(gym: oldGym(secondRow: #"{"name":"Stairs"}"#))
        #expect(p.gym.ideas == ["Lunges", "Stairs", "Plank"])
        expectRestKept(p)
    }

    @Test func oldRowWithANumberNameIsDroppedAndTheRestStays() throws {
        let p = try load(gym: oldGym(secondRow: #"{"name":42,"minutes":3}"#))
        #expect(p.gym.ideas == ["Lunges", "Plank"])
        expectRestKept(p)
    }

    @Test func oldRowWithABlankNameIsDropped() throws {
        let p = try load(gym: oldGym(secondRow: #"{"name":"   ","minutes":3}"#))
        #expect(p.gym.ideas == ["Lunges", "Plank"])
        expectRestKept(p)
    }

    @Test func anIdeaThatIsNotTextIsDroppedAndTheRestStays() throws {
        let p = try load(gym: #"{"enabled":true,"sessionsPerDay":3,"sessionMinutes":10,"ideas":["Plank",42,"Jog"]}"#)
        #expect(p.gym.ideas == ["Plank", "Jog"])
        #expect(p.gym.sessionsPerDay == 3)
        #expect(p.gym.sessionMinutes == 10)
        expectRestKept(p)
    }

    @Test func offListGymNumbersLoadTheNearestAndKeepTheRest() throws {
        let p = try load(gym: #"{"enabled":true,"sessionsPerDay":99,"sessionMinutes":7,"ideas":["Plank"]}"#)
        #expect(p.gym.sessionsPerDay == 8)
        #expect(p.gym.sessionMinutes == 5)
        #expect(p.gym.ideas == ["Plank"])
        expectRestKept(p)
    }

    @Test func savedFileHasNoIntervalAndKeepsTheNewFields() throws {
        let store = FileStateStore(base: base, delay: 3600)
        var p = Prefs()
        p.gym.sessionsPerDay = 6
        p.gym.sessionMinutes = 10
        p.gym.ideas = ["Plank"]
        store.savePrefs(p)
        #expect(store.flush())
        let raw = try #require(readJSONObject(prefsURL))
        let gym = try #require((raw["value"] as? [String: Any])?["gym"] as? [String: Any])
        #expect(gym["intervalMinutes"] == nil)
        #expect(gym["sessionsPerDay"] as? Int == 6)
        #expect(gym["sessionMinutes"] as? Int == 10)
        #expect(gym["ideas"] as? [String] == ["Plank"])
    }
}
