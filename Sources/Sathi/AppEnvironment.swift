import SathiCore
import SathiUI

@MainActor
enum AppEnvironment {
    static let presenter = UIController()

    static let engine: Engine = {
        let engine = Engine(
            store: UserDefaultsStateStore(),
            clock: SystemClock(),
            sound: SystemSoundPlayer(),
            presenter: presenter
        )
        presenter.engine = engine
        return engine
    }()
}
