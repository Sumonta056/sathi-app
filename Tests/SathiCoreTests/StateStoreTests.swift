import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("UserDefaultsStateStore")
struct StateStoreTests {
    private func freshDefaults() -> UserDefaults {
        let name = "sathi.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func emptyStoreLoadsDefaults() {
        #expect(UserDefaultsStateStore(defaults: freshDefaults()).load() == Persisted())
    }

    @Test func saveThenLoadRoundTrips() {
        let store = UserDefaultsStateStore(defaults: freshDefaults())
        var state = Persisted()
        state.prefs.name = "Test"
        state.drinks = [DrinkEntry(date: day(2026, 3, 4, 10), glasses: 1)]
        store.save(state)
        #expect(store.load() == state)
    }

    @Test func corruptDataFallsBackToDefaults() {
        let defaults = freshDefaults()
        defaults.set(Data("not json".utf8), forKey: StorageKeys.state)
        #expect(UserDefaultsStateStore(defaults: defaults).load() == Persisted())
    }
}
