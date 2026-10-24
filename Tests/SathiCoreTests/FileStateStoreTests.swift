import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("FileStateStore")
struct FileStateStoreTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }
    private var stateURL: URL { base.appendingPathComponent("state.json") }

    private var customPrefs: Prefs {
        var p = Prefs()
        p.general.name = "Asha"
        p.water.intervalMinutes = 45
        p.reading.timeMinutes = 1260
        return p
    }

    private var customLive: LiveState {
        var live = LiveState()
        live.bottleLevel = 0.25
        live.lastWaterDone = day(2026, 3, 4, 10)
        live.streakReset = [HabitID.water.rawValue: day(2026, 3, 1, 8)]
        return live
    }

    @Test func emptyFolderLoadsDefaults() {
        let store = FileStateStore(base: base)
        #expect(store.loadPrefs() == Prefs())
        #expect(store.loadLive() == LiveState())
    }

    @Test func saveFlushThenNewStoreLoadsTheSame() {
        let store = FileStateStore(base: base)
        store.savePrefs(customPrefs)
        store.saveLive(customLive)
        #expect(store.flush())
        let reopened = FileStateStore(base: base)
        #expect(reopened.loadPrefs() == customPrefs)
        #expect(reopened.loadLive() == customLive)
    }

    @Test func theLastSaveWins() {
        let store = FileStateStore(base: base)
        store.savePrefs(Prefs())
        store.savePrefs(customPrefs)
        store.flush()
        #expect(FileStateStore(base: base).loadPrefs() == customPrefs)
    }

    @Test func filesCarryTheSchemaVersion() throws {
        let store = FileStateStore(base: base)
        store.savePrefs(customPrefs)
        store.saveLive(customLive)
        store.flush()
        let prefs = try #require(readJSONObject(prefsURL))
        #expect(prefs["schemaVersion"] as? Int == 1)
        let value = try #require(prefs["value"] as? [String: Any])
        let general = try #require(value["general"] as? [String: Any])
        #expect(general["name"] as? String == "Asha")
        let state = try #require(readJSONObject(stateURL))
        #expect(state["schemaVersion"] as? Int == 1)
        let live = try #require(state["value"] as? [String: Any])
        #expect(live["bottleLevel"] as? Double == 0.25)
    }

    @Test func noFileIsWrittenBeforeFlush() {
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(customPrefs)
        store.saveLive(customLive)
        #expect(!fileExists(prefsURL))
        #expect(!fileExists(stateURL))
        store.flush()
        #expect(fileExists(prefsURL))
        #expect(fileExists(stateURL))
    }

    @Test func corruptPrefsLoadsDefaultsAndKeepsTheFile() throws {
        try writeText("not json", to: prefsURL)
        let store = FileStateStore(base: base)
        #expect(store.loadPrefs() == Prefs())
        #expect(readText(base.appendingPathComponent("prefs.json.corrupt")) == "not json")
    }

    @Test func corruptFileReplacesAnOlderCorruptCopy() throws {
        try writeText("old", to: base.appendingPathComponent("prefs.json.corrupt"))
        try writeText("new garbage", to: prefsURL)
        #expect(FileStateStore(base: base).loadPrefs() == Prefs())
        #expect(readText(base.appendingPathComponent("prefs.json.corrupt")) == "new garbage")
    }

    @Test func corruptStateLoadsDefaultsAndKeepsTheFile() throws {
        try writeText("{\"schemaVersion\":1,\"value\":42}", to: stateURL)
        #expect(FileStateStore(base: base).loadLive() == LiveState())
        #expect(readText(base.appendingPathComponent("state.json.corrupt")) == "{\"schemaVersion\":1,\"value\":42}")
    }

    @Test func partialPrefsFileKeepsTheOtherDefaults() throws {
        try writeText(#"{"schemaVersion":1,"value":{"water":{"intervalMinutes":60}}}"#, to: prefsURL)
        var expected = Prefs()
        expected.water.intervalMinutes = 60
        #expect(FileStateStore(base: base).loadPrefs() == expected)
    }
}
