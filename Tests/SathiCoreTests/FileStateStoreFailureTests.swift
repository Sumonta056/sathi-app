import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("FileStateStore failures")
struct FileStateStoreFailureTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }
    private var corruptURL: URL { base.appendingPathComponent("prefs.json.corrupt") }

    private func store() -> FileStateStore { FileStateStore(base: base, delay: 3600) }

    private func prefs(named name: String) -> Prefs {
        var p = Prefs()
        p.general.name = name
        return p
    }

    private var customLive: LiveState {
        var live = LiveState()
        live.bottleLevel = 0.25
        live.lastWaterDone = day(2026, 3, 4, 10)
        return live
    }

    @Test func flushWithNothingPendingReturnsTrue() {
        #expect(store().flush())
    }

    @Test func failedSaveIsKeptAndWrittenByTheNextFlush() throws {
        try makeFolder(base)
        defer { try? setPermissions(0o700, base) }
        let s = store()
        try setPermissions(0o500, base)
        s.savePrefs(prefs(named: "First"))
        s.saveLive(customLive)
        #expect(!s.flush())
        s.savePrefs(prefs(named: "Last"))
        try setPermissions(0o700, base)
        #expect(s.flush())
        let reopened = store()
        #expect(reopened.loadPrefs() == prefs(named: "Last"))
        #expect(reopened.loadLive() == customLive)
    }

    @Test func unreadablePrefsFileIsNeverOverwritten() throws {
        let s = store()
        s.savePrefs(prefs(named: "Original"))
        s.flush()
        let before = try #require(readData(prefsURL))
        try setPermissions(0o000, prefsURL)
        defer { try? setPermissions(0o600, prefsURL) }
        let unreadable = store()
        #expect(unreadable.loadPrefs() == Prefs())
        unreadable.savePrefs(prefs(named: "Changed"))
        unreadable.flush()
        try setPermissions(0o600, prefsURL)
        #expect(readData(prefsURL) == before)
        #expect(!fileExists(corruptURL))
    }

    @Test func savesToAnUnreadableFileStayInMemory() throws {
        try writeText("x", to: prefsURL)
        try setPermissions(0o000, prefsURL)
        defer { try? setPermissions(0o600, prefsURL) }
        let s = store()
        _ = s.loadPrefs()
        s.savePrefs(prefs(named: "Changed"))
        s.flush()
        #expect(s.loadPrefs() == prefs(named: "Changed"))
    }

    @Test func failedQuarantineKeepsBothFilesAndBlocksWrites() throws {
        try writeText("old", to: corruptURL)
        try writeText("new garbage", to: prefsURL)
        defer { try? setPermissions(0o700, base) }
        try setPermissions(0o500, base)
        let s = store()
        #expect(s.loadPrefs() == Prefs())
        try setPermissions(0o700, base)
        s.savePrefs(prefs(named: "Changed"))
        s.flush()
        #expect(readText(prefsURL) == "new garbage")
        #expect(readText(corruptURL) == "old")
        #expect(s.loadPrefs() == prefs(named: "Changed"))
    }
}
