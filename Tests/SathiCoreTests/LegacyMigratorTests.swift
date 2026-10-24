import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("LegacyMigrator")
struct LegacyMigratorTests {
    private typealias Fix = LegacyV1Fixture
    private let base = makeTempFolder()

    private func migrate(_ defaults: UserDefaults, _ state: StateStore, _ history: HistoryStore) -> Bool {
        LegacyMigrator.migrateIfNeeded(defaults: defaults, state: state, history: history, base: base)
    }

    private func fileStores() -> (FileStateStore, FileHistoryStore) {
        (FileStateStore(base: base, delay: 3600), FileHistoryStore(base: base, calendar: .current, delay: 3600))
    }

    @Test func mapsV1DataToPrefsLiveStateAndEvents() {
        let state = InMemoryStateStore()
        let history = InMemoryHistoryStore()
        #expect(migrate(Fix.defaults(), state, history))
        #expect(state.prefs == Fix.prefs)
        #expect(state.live == Fix.live)
        #expect(history.appended.sorted { $0.date < $1.date } == Fix.events)
        #expect(state.flushes > 0)
        #expect(history.flushes > 0)
        #expect(fileExists(Fix.marker(base)))
    }

    @Test func runsOnlyOnce() {
        let defaults = Fix.defaults()
        let (state, history) = fileStores()
        #expect(migrate(defaults, state, history))
        #expect(!migrate(defaults, state, history))
        history.flush()
        #expect(Fix.storedEvents(base) == Fix.events)
        #expect(FileStateStore(base: base).loadPrefs() == Fix.prefs)
    }

    @Test func doesNothingWhenTheMarkerExists() throws {
        try writeText("1", to: Fix.marker(base))
        let state = InMemoryStateStore()
        let history = InMemoryHistoryStore()
        #expect(!migrate(Fix.defaults(), state, history))
        #expect(state.prefsSaves == 0)
        #expect(state.liveSaves == 0)
        #expect(history.appended.isEmpty)
    }

    @Test func doesNothingWithoutTheLegacyKey() throws {
        let name = "sathi.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        let state = InMemoryStateStore()
        let history = InMemoryHistoryStore()
        #expect(!migrate(defaults, state, history))
        #expect(state.prefsSaves == 0)
        #expect(history.appended.isEmpty)
        #expect(!fileExists(Fix.marker(base)))
    }

    @Test func doesNothingWhenTheLegacyKeyDoesNotDecode() {
        let state = InMemoryStateStore()
        let history = InMemoryHistoryStore()
        #expect(!migrate(Fix.defaults("not json"), state, history))
        #expect(state.prefsSaves == 0)
        #expect(history.appended.isEmpty)
        #expect(!fileExists(Fix.marker(base)))
    }

    @Test func keepsTheOldKey() {
        let defaults = Fix.defaults()
        _ = migrate(defaults, InMemoryStateStore(), InMemoryHistoryStore())
        #expect(defaults.data(forKey: "sathi.state.v1") == Data(Fix.json.utf8))
    }

    @Test func failedHistoryFlushWritesNoMarker() {
        let history = InMemoryHistoryStore()
        history.failFlush = true
        #expect(!migrate(Fix.defaults(), InMemoryStateStore(), history))
        #expect(!fileExists(Fix.marker(base)))
    }

    @Test func failedStateFlushWritesNoMarker() {
        let state = InMemoryStateStore()
        state.failFlush = true
        #expect(!migrate(Fix.defaults(), state, InMemoryHistoryStore()))
        #expect(!fileExists(Fix.marker(base)))
    }

    @Test func skipsLegacyEventsTheHistoryAlreadyHolds() {
        let other = HistoryEvent.snooze(.water, at: Fix.at(792_403_200))
        let history = InMemoryHistoryStore(events: [Fix.events[0], Fix.events[3], other])
        #expect(migrate(Fix.defaults(), InMemoryStateStore(), history))
        #expect(history.appended.sorted { $0.date < $1.date } == [Fix.events[1], Fix.events[2], Fix.events[4]])
        #expect(history.events.count == 6)
    }

    @Test func storageNamesAreStable() {
        #expect(StorageKeys.legacyV1 == "sathi.state.v1")
        #expect(StorageKeys.migrationMarker == "migrated-v1")
    }
}
