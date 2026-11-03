import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Close button prefs")
struct CloseButtonPrefsTests {
    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    private func roundTrip(_ p: Prefs) throws -> Prefs {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try JSONDecoder().decode(Prefs.self, from: encoder.encode(p))
    }

    @Test func everyHabitShowsTheCloseButtonByDefault() {
        let p = Prefs()
        #expect(p.water.showsCloseButton)
        #expect(p.reading.showsCloseButton)
        #expect(p.meditation.showsCloseButton)
        #expect(p.gym.showsCloseButton)
        for id in HabitID.allCases {
            #expect(p.showsCloseButton(id))
        }
    }

    @Test(arguments: HabitID.allCases)
    func setterChangesOnlyThatHabit(_ id: HabitID) {
        var p = Prefs()
        p.setShowsCloseButton(id, false)
        #expect(!p.showsCloseButton(id))
        for other in HabitID.allCases where other != id {
            #expect(p.showsCloseButton(other))
        }
        p.setShowsCloseButton(id, true)
        #expect(p.showsCloseButton(id))
    }

    @Test func setterWritesTheHabitField() {
        var p = Prefs()
        for id in HabitID.allCases {
            p.setShowsCloseButton(id, false)
        }
        #expect(!p.water.showsCloseButton)
        #expect(!p.reading.showsCloseButton)
        #expect(!p.meditation.showsCloseButton)
        #expect(!p.gym.showsCloseButton)
        for id in HabitID.allCases {
            p.setShowsCloseButton(id, true)
        }
        #expect(p.water.showsCloseButton)
        #expect(p.reading.showsCloseButton)
        #expect(p.meditation.showsCloseButton)
        #expect(p.gym.showsCloseButton)
    }

    @Test(arguments: HabitID.allCases)
    func prefsWithoutTheKeyDecodeToOn(_ id: HabitID) throws {
        let json = #"{"water":{"enabled":true},"reading":{"enabled":true},"meditation":{"enabled":true},"gym":{"enabled":true}}"#
        let p = try decode(json)
        #expect(p.showsCloseButton(id))
        #expect(p.isEnabled(id))
    }

    @Test func eachHabitSectionWithoutTheKeyDecodesToOn() throws {
        #expect(try JSONDecoder().decode(WaterPrefs.self, from: Data(#"{"intervalMinutes":90}"#.utf8)).showsCloseButton)
        #expect(try JSONDecoder().decode(ReadingPrefs.self, from: Data(#"{"sessionMinutes":20}"#.utf8)).showsCloseButton)
        #expect(try JSONDecoder().decode(MeditationPrefs.self, from: Data(#"{"sessionMinutes":5}"#.utf8)).showsCloseButton)
        #expect(try JSONDecoder().decode(GymPrefs.self, from: Data(#"{"intervalMinutes":45}"#.utf8)).showsCloseButton)
    }

    @Test(arguments: HabitID.allCases)
    func offSurvivesARoundTrip(_ id: HabitID) throws {
        var p = Prefs()
        p.setShowsCloseButton(id, false)
        let back = try roundTrip(p)
        #expect(!back.showsCloseButton(id))
        for other in HabitID.allCases where other != id {
            #expect(back.showsCloseButton(other))
        }
        #expect(back == p)
    }

    @Test func encodedPrefsHoldTheKey() throws {
        var p = Prefs()
        p.setShowsCloseButton(.gym, false)
        let text = try #require(String(bytes: JSONEncoder().encode(p.gym), encoding: .utf8))
        #expect(text.contains(#""showsCloseButton":false"#))
        let water = try #require(String(bytes: JSONEncoder().encode(p.water), encoding: .utf8))
        #expect(water.contains(#""showsCloseButton":true"#))
    }

    @Test func savedFileKeepsOff() {
        let base = makeTempFolder()
        var p = Prefs()
        p.setShowsCloseButton(.reading, false)
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(p)
        #expect(store.flush())
        let loaded = FileStateStore(base: base).loadPrefs()
        #expect(!loaded.showsCloseButton(.reading))
        #expect(loaded.showsCloseButton(.water))
    }

    @Test(arguments: HabitID.allCases, [(true, Level.nudge, true), (true, .persist, false), (false, .nudge, false), (false, .persist, false)])
    func engineShowsCloseOnlyWhenOnAtNudge(_ id: HabitID, _ row: (Bool, Level, Bool)) {
        let h = EngineHarness { $0.prefs.setShowsCloseButton(id, row.0) }
        #expect(h.engine.showsClose(id, level: row.1) == row.2)
    }

    @Test(arguments: HabitID.allCases)
    func engineFollowsAPrefChange(_ id: HabitID) {
        let h = EngineHarness()
        #expect(h.engine.showsClose(id, level: .nudge))
        h.engine.data.prefs.setShowsCloseButton(id, false)
        #expect(!h.engine.showsClose(id, level: .nudge))
        #expect(h.store.prefs.showsCloseButton(id) == false)
    }
}
