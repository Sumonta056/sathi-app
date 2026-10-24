import Foundation

package enum LegacyMigrator {
    @discardableResult
    package static func migrateIfNeeded(
        defaults: UserDefaults,
        state: StateStore,
        history: HistoryStore,
        base: URL
    ) -> Bool {
        let marker = base.appendingPathComponent(StorageKeys.migrationMarker)
        guard !exists(base, StorageKeys.migrationMarker),
              let raw = defaults.data(forKey: StorageKeys.legacyV1),
              let old = try? JSONDecoder().decode(LegacyV1.self, from: raw) else { return false }
        appendMissing(old.events, to: history)
        guard history.flush() else { return false }
        if !exists(base, StorageKeys.prefsFile) { state.savePrefs(old.prefs.prefs) }
        if !exists(base, StorageKeys.stateFile) { state.saveLive(old.live) }
        guard state.flush() else { return false }
        return writeMarker(marker)
    }

    private static func appendMissing(_ events: [HistoryEvent], to history: HistoryStore) {
        guard let first = events.map(\.date).min(), let last = events.map(\.date).max() else { return }
        let existing = history.events(from: first, to: last.addingTimeInterval(Timing.second))
        events.filter { !existing.contains($0) }.forEach(history.append)
    }

    private static func exists(_ base: URL, _ name: String) -> Bool {
        FileManager.default.fileExists(atPath: base.appendingPathComponent(name).path)
    }

    private static func writeMarker(_ url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("1".utf8).write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
