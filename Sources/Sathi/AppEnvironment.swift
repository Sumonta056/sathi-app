import Foundation
import SathiCore
import SathiUI

@MainActor
enum AppEnvironment {
    static let presenter = UIController()

    static let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(StorageKeys.appFolder)
    static let stateStore = FileStateStore(base: base)
    static let historyStore = FileHistoryStore(base: base, calendar: .current)

    static let engine: Engine = {
        LegacyMigrator.migrateIfNeeded(
            defaults: .standard,
            state: stateStore,
            history: historyStore,
            base: base
        )
        let engine = Engine(
            store: stateStore,
            history: historyStore,
            clock: SystemClock(),
            sound: SystemSoundPlayer(),
            presenter: presenter
        )
        presenter.engine = engine
        return engine
    }()
}
