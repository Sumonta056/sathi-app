import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Away places prefs storage")
struct AwayPlacePrefsStorageTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func theDefaultIsNoPlaces() {
        #expect(TrackerPrefs().awayPlaces == [])
    }

    @Test func oldPrefsWithoutTheKeyLoadNoPlacesAndKeepTheRest() throws {
        let p = try prefs(#"{"tracker":{"isOn":true,"askEveryMinutes":20},"water":{"intervalMinutes":45}}"#)
        #expect(p.tracker.awayPlaces == [])
        #expect(p.tracker.isOn)
        #expect(p.tracker.askEveryMinutes == 20)
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func oneKnownKeyKeepsTheOtherDefaults() throws {
        let p = try prefs(#"{"tracker":{"awayPlaces":["Doctor","Gym"]}}"#)
        var expected = Prefs()
        expected.tracker.awayPlaces = ["Doctor", "Gym"]
        #expect(p == expected)
    }

    @Test func aPartialPrefsFileKeepsTheOtherDefaults() throws {
        try writeText(#"{"schemaVersion":1,"value":{"tracker":{"awayPlaces":["Doctor"]}}}"#, to: prefsURL)
        var expected = Prefs()
        expected.tracker.awayPlaces = ["Doctor"]
        #expect(FileStateStore(base: base).loadPrefs() == expected)
    }

    @Test func anOldPrefsFileWithoutTheKeyLoadsNoPlaces() throws {
        try writeText(#"{"schemaVersion":1,"value":{"tracker":{"isOn":true,"idleMinutes":60}}}"#, to: prefsURL)
        var expected = Prefs()
        expected.tracker.isOn = true
        expected.tracker.idleMinutes = 60
        #expect(FileStateStore(base: base).loadPrefs() == expected)
    }

    @Test func placesRoundTrip() throws {
        var p = Prefs()
        p.tracker.awayPlaces = ["Doctor", "School run", "Gym"]
        p.tracker.isOn = true
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back == p)
        #expect(back.tracker.awayPlaces == ["Doctor", "School run", "Gym"])
    }

    @Test func placesAreWrittenUnderTheirKeyAndLoadBackInANewStore() throws {
        var p = Prefs()
        p.tracker.awayPlaces = ["Doctor", "Gym"]
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(p)
        #expect(!fileExists(prefsURL))
        #expect(store.flush())
        let json = try #require(readJSONObject(prefsURL))
        let value = try #require(json["value"] as? [String: Any])
        let tracker = try #require(value["tracker"] as? [String: Any])
        #expect(tracker["awayPlaces"] as? [String] == ["Doctor", "Gym"])
        #expect(FileStateStore(base: base).loadPrefs() == p)
    }

    @Test(arguments: [#""oops""#, "7", "true", #"{"a":"Doctor"}"#, "null"])
    func aWrongTypeLoadsNoPlacesAndNeverResetsTheOtherSettings(_ bad: String) throws {
        let json = #"{"tracker":{"awayPlaces":"# + bad + #","isOn":true,"askEveryMinutes":20,"idleMinutes":60},"#
            + #""water":{"intervalMinutes":45},"general":{"name":"Asha"}}"#
        let p = try prefs(json)
        #expect(p.tracker.awayPlaces == [])
        #expect(p.tracker.isOn)
        #expect(p.tracker.askEveryMinutes == 20)
        #expect(p.tracker.idleMinutes == 60)
        #expect(p.water.intervalMinutes == 45)
        #expect(p.general.name == "Asha")
    }

    @Test func decodeCleansTheList() throws {
        let p = try prefs(#"{"tracker":{"awayPlaces":["  Doctor ","doctor","Lunch","","break","Gym"],"isOn":true}}"#)
        #expect(p.tracker.awayPlaces == ["Doctor", "Gym"])
        #expect(p.tracker.isOn)
    }

    @Test func decodeKeepsTheFirstEightAndCutsLongNames() throws {
        let names = (1 ... 10).map { "\"P\($0)\"" }.joined(separator: ",")
        let p = try prefs(#"{"tracker":{"awayPlaces":["# + names + "]}}")
        #expect(p.tracker.awayPlaces == ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"])
        let long = String(repeating: "a", count: 40)
        let cut = try prefs(#"{"tracker":{"awayPlaces":[""# + long + #""]}}"#)
        #expect(cut.tracker.awayPlaces == [String(repeating: "a", count: 24)])
    }
}
