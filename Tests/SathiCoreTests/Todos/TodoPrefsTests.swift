import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoPrefs")
struct TodoPrefsTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func defaults() {
        let p = TodoPrefs()
        #expect(!p.isOn)
        #expect(p.hiddenListIDs.isEmpty)
        #expect(p.askWhenDue)
        #expect(p.newListAccountID == nil)
        #expect(Prefs().todos == TodoPrefs())
    }

    @Test func oldPrefsWithoutTheKeyLoadDefaults() throws {
        let p = try prefs(#"{"water":{"intervalMinutes":45},"general":{"name":"Asha"}}"#)
        #expect(p.todos == TodoPrefs())
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func aBadTodosValueFallsBackAndKeepsOtherSettings() throws {
        let p = try prefs(#"{"todos":"oops","water":{"intervalMinutes":45}}"#)
        #expect(p.todos == TodoPrefs())
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func emptyTodosObjectLoadsDefaults() throws {
        #expect(try prefs(#"{"todos":{}}"#).todos == TodoPrefs())
    }

    @Test func savedValuesLoad() throws {
        let json = #"{"todos":{"isOn":true,"hiddenListIDs":["a","b"],"askWhenDue":false,"newListAccountID":"ic"}}"#
        let p = try prefs(json)
        #expect(p.todos.isOn)
        #expect(p.todos.hiddenListIDs == ["a", "b"])
        #expect(!p.todos.askWhenDue)
        #expect(p.todos.newListAccountID == "ic")
    }

    @Test func roundTrips() throws {
        var p = Prefs()
        p.todos = TodoPrefs(isOn: true, hiddenListIDs: ["x"], askWhenDue: false, newListAccountID: "ic")
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.todos == p.todos)
    }
}

@Suite("TodoPrefs file")
struct TodoPrefsFileTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    @Test func anOldPrefsFileWithoutTodosStillLoads() throws {
        try writeText(#"{"schemaVersion":1,"value":{"water":{"intervalMinutes":60}}}"#, to: prefsURL)
        let loaded = FileStateStore(base: base).loadPrefs()
        #expect(loaded.water.intervalMinutes == 60)
        #expect(loaded.todos == TodoPrefs())
        #expect(!fileExists(base.appendingPathComponent("prefs.json.corrupt")))
    }

    @Test func todosPrefsSurviveSaveAndReload() {
        var p = Prefs()
        p.todos = TodoPrefs(isOn: true, hiddenListIDs: ["x"], askWhenDue: false, newListAccountID: "ic")
        let store = FileStateStore(base: base, delay: 3600)
        store.savePrefs(p)
        store.flush()
        #expect(FileStateStore(base: base).loadPrefs().todos == p.todos)
    }
}
