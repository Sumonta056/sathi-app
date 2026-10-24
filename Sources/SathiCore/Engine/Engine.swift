import Combine
import Foundation

@MainActor
package final class Engine: ObservableObject {
    @Published package var data: Persisted {
        didSet {
            streakCache.removeAll()
            if oldValue.prefs.scheduleKey != data.prefs.scheduleKey { reschedule() }
            store.save(data)
        }
    }
    @Published package var now: Date
    @Published package var phase: Phase = .idle
    @Published package var pausedUntil: Date?
    @Published package var water: HabitState
    @Published package var reading: HabitState
    @Published package var queue: [HabitID] = []
    @Published package var copy = Copy()
    @Published package var celebration = Celebration()
    @Published package var ignoreDeadline: Date
    @Published package var sessionStart: Date
    @Published package var sessionEnd: Date

    package let status = StatusModel()
    let store: StateStore
    let clock: Clock
    let sound: SoundPlayer
    let presenter: ReminderPresenter
    let calendar: Calendar

    var timer: Timer?
    var isRunning = false
    var forced: Set<HabitID> = []
    var celebrateToken = UUID()
    var streakCache: [HabitID: Int] = [:]
    var streakCacheDay: Date?

    package init(
        store: StateStore,
        clock: Clock,
        sound: SoundPlayer,
        presenter: ReminderPresenter,
        calendar: Calendar = .current
    ) {
        let loaded = store.load()
        let n = clock.now
        self.store = store
        self.clock = clock
        self.sound = sound
        self.presenter = presenter
        self.calendar = calendar
        data = loaded
        now = n
        ignoreDeadline = n
        sessionStart = n
        sessionEnd = n
        let scheduler = Scheduler(prefs: loaded.prefs, calendar: calendar)
        let readToday = Stats(calendar: calendar).readMinutes(on: n, in: loaded.reads)
        water = HabitState(nextDue: scheduler.nextWaterDue(after: loaded.lastWaterDone ?? n))
        reading = HabitState(nextDue: scheduler.nextReadingDue(now: n, readToday: readToday, skipToday: false))
    }

    package var scheduler: Scheduler { Scheduler(prefs: data.prefs, calendar: calendar) }
    var stats: Stats { Stats(calendar: calendar) }

    package func enabled(_ id: HabitID) -> Bool { data.prefs.isEnabled(id) }
    package func state(_ id: HabitID) -> HabitState { id == .water ? water : reading }
    package func strictness(_ id: HabitID) -> Strictness { data.prefs.strictness(id) }

    func update(_ id: HabitID, _ change: (inout HabitState) -> Void) {
        if id == .water { change(&water) } else { change(&reading) }
    }

    package func isActive(_ id: HabitID) -> Bool {
        switch phase {
        case let .bubble(h, _): return h == id
        case let .lock(h): return h == id
        case .session: return id == .reading
        default: return false
        }
    }

    package func isDue(_ id: HabitID) -> Bool { isActive(id) || queue.contains(id) }
}
