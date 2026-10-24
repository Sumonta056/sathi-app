import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("LegacyMigrator recovery")
struct LegacyMigratorRecoveryTests {
    private typealias Fix = LegacyV1Fixture
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }

    private func migrate(_ defaults: UserDefaults, _ state: StateStore, _ history: HistoryStore) -> Bool {
        LegacyMigrator.migrateIfNeeded(defaults: defaults, state: state, history: history, base: base)
    }

    private func migrateWithFreshStores(_ defaults: UserDefaults) -> Bool {
        migrate(defaults, FileStateStore(base: base, delay: 3600), FileHistoryStore(base: base, calendar: .current, delay: 3600))
    }

    @Test func failedHistoryFlushIsRetriedOnTheNextCall() throws {
        let folder = base.appendingPathComponent("history")
        try makeFolder(folder)
        defer { try? setPermissions(0o700, folder) }
        let defaults = Fix.defaults()
        let state = FileStateStore(base: base, delay: 3600)
        let history = FileHistoryStore(base: base, calendar: .current, delay: 3600)
        try setPermissions(0o500, folder)
        #expect(!migrate(defaults, state, history))
        #expect(!fileExists(Fix.marker(base)))
        try setPermissions(0o700, folder)
        #expect(migrate(defaults, state, history))
        #expect(fileExists(Fix.marker(base)))
        #expect(Fix.storedEvents(base) == Fix.events)
        #expect(FileStateStore(base: base).loadPrefs() == Fix.prefs)
    }

    @Test func deletedPrefsFileDoesNotStartTheMigrationAgain() throws {
        let defaults = Fix.defaults()
        #expect(migrateWithFreshStores(defaults))
        try FileManager.default.removeItem(at: prefsURL)
        #expect(!migrateWithFreshStores(defaults))
        #expect(!fileExists(prefsURL))
        #expect(Fix.storedEvents(base) == Fix.events)
    }

    @Test func secondRunAfterTheMarkerIsDeletedKeepsOneCopyOfEachEvent() throws {
        let defaults = Fix.defaults()
        #expect(migrateWithFreshStores(defaults))
        try FileManager.default.removeItem(at: Fix.marker(base))
        #expect(migrateWithFreshStores(defaults))
        #expect(fileExists(Fix.marker(base)))
        #expect(Fix.storedEvents(base) == Fix.events)
    }
}
