import Foundation

package protocol StateStore {
    func load() -> Persisted
    func save(_ state: Persisted)
}

package struct UserDefaultsStateStore: StateStore {
    private let defaults: UserDefaults
    private let key: String

    package init(defaults: UserDefaults = .standard, key: String = StorageKeys.state) {
        self.defaults = defaults
        self.key = key
    }

    package func load() -> Persisted {
        guard let raw = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: raw) else { return Persisted() }
        return decoded
    }

    package func save(_ state: Persisted) {
        guard let raw = try? JSONEncoder().encode(state) else { return }
        defaults.set(raw, forKey: key)
    }
}
