import Foundation

package final class FileStateStore: StateStore, @unchecked Sendable {
    private let delay: TimeInterval
    private let queue = DispatchQueue(label: "sathi.state-store")
    private var prefs: FileSlot<Prefs>
    private var live: FileSlot<LiveState>
    private var isScheduled = false

    package init(base: URL, delay: TimeInterval = Timing.saveCoalesce) {
        self.delay = delay
        prefs = FileSlot(url: base.appendingPathComponent(StorageKeys.prefsFile))
        live = FileSlot(url: base.appendingPathComponent(StorageKeys.stateFile))
    }

    package func loadPrefs() -> Prefs {
        queue.sync { prefs.load() ?? Prefs() }
    }

    package func loadLive() -> LiveState {
        queue.sync { live.load() ?? LiveState() }
    }

    package func savePrefs(_ value: Prefs) {
        queue.async { [self] in
            prefs.pending = value
            scheduleWrite()
        }
    }

    package func saveLive(_ value: LiveState) {
        queue.async { [self] in
            live.pending = value
            scheduleWrite()
        }
    }

    @discardableResult
    package func flush() -> Bool {
        queue.sync { writePending() }
    }

    private func scheduleWrite() {
        guard !isScheduled else { return }
        isScheduled = true
        queue.asyncAfter(deadline: .now() + delay) { [self] in writePending() }
    }

    @discardableResult
    private func writePending() -> Bool {
        isScheduled = false
        let prefsOK = prefs.write()
        let liveOK = live.write()
        return prefsOK && liveOK
    }
}
