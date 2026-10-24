import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("LegacyMigrator re-run")
struct LegacyMigratorRerunTests {
    private typealias Fix = LegacyV1Fixture
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }
    private var stateURL: URL { base.appendingPathComponent("state.json") }

    private var userPrefs: Prefs {
        var p = Prefs()
        p.general.name = "Changed later"
        p.water.intervalMinutes = 30
        return p
    }

    private var userLive: LiveState {
        var live = LiveState()
        live.bottleLevel = 0.75
        live.lastWaterDone = day(2026, 3, 4, 10)
        return live
    }

    private func migrate(_ defaults: UserDefaults, _ state: StateStore, _ history: HistoryStore) -> Bool {
        LegacyMigrator.migrateIfNeeded(defaults: defaults, state: state, history: history, base: base)
    }

    private func migrateWithFreshStores(_ defaults: UserDefaults) -> Bool {
        migrate(defaults, FileStateStore(base: base, delay: 3600), FileHistoryStore(base: base, calendar: .current, delay: 3600))
    }

    @Test func reRunAfterAFailedStateFlushKeepsNewerStateAndOneCopyOfEachEvent() throws {
        try makeFolder(base.appendingPathComponent("history"))
        defer { try? setPermissions(0o700, base) }
        let defaults = Fix.defaults()
        try setPermissions(0o500, base)
        #expect(!migrateWithFreshStores(defaults))
        try setPermissions(0o700, base)
        #expect(!fileExists(Fix.marker(base)))
        #expect(Fix.storedEvents(base) == Fix.events)
        let user = FileStateStore(base: base, delay: 3600)
        user.savePrefs(userPrefs)
        user.saveLive(userLive)
        #expect(user.flush())
        let prefsBytes = readData(prefsURL)
        let stateBytes = readData(stateURL)
        #expect(migrateWithFreshStores(defaults))
        #expect(fileExists(Fix.marker(base)))
        #expect(readData(prefsURL) == prefsBytes)
        #expect(readData(stateURL) == stateBytes)
        #expect(FileStateStore(base: base, delay: 3600).loadPrefs() == userPrefs)
        #expect(FileStateStore(base: base, delay: 3600).loadLive() == userLive)
        #expect(Fix.storedEvents(base) == Fix.events)
    }

    @Test func existingPrefsFileIsNotOverwritten() throws {
        try writeText("{}", to: prefsURL)
        let state = InMemoryStateStore()
        #expect(migrate(Fix.defaults(), state, InMemoryHistoryStore()))
        #expect(state.prefsSaves == 0)
        #expect(state.live == Fix.live)
    }

    @Test func existingStateFileIsNotOverwritten() throws {
        try writeText("{}", to: stateURL)
        let state = InMemoryStateStore()
        #expect(migrate(Fix.defaults(), state, InMemoryHistoryStore()))
        #expect(state.liveSaves == 0)
        #expect(state.prefs == Fix.prefs)
    }

    @Test func fractionalLegacyLiveDatesAreStoredToTheWholeSecond() {
        let blob = Fix.json
            .replacingOccurrences(of: "\"lastWaterDone\": 792590400", with: "\"lastWaterDone\": 792590400.25")
            .replacingOccurrences(of: "{\"water\": 792320400}", with: "{\"water\": 792320400.9}")
        let state = InMemoryStateStore()
        #expect(migrate(Fix.defaults(blob), state, InMemoryHistoryStore()))
        #expect(state.live == Fix.live)
    }
}
