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
    @Published package internal(set) var habits: [HabitID: HabitState]
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
        habits = Dictionary(uniqueKeysWithValues: HabitID.allCases.map { id in
            let r = id.rules(loaded.prefs, calendar: calendar)
            let due = r.nextDue(
                now: n,
                lastDone: loaded.lastDone(id),
                doneToday: r.total(on: n, data: loaded),
                skipToday: false
            )
            return (id, HabitState(nextDue: due))
        })
    }

    var stats: Stats { Stats(calendar: calendar) }

    func rules(_ id: HabitID) -> any HabitRules { id.rules(data.prefs, calendar: calendar) }

    func freshDue(_ id: HabitID, lastDone: Date?, skipToday: Bool = false) -> Date {
        let r = rules(id)
        let n = clock.now
        return r.nextDue(now: n, lastDone: lastDone, doneToday: r.total(on: n, data: data), skipToday: skipToday)
    }

    package func enabled(_ id: HabitID) -> Bool { data.prefs.isEnabled(id) }
    package func state(_ id: HabitID) -> HabitState { habits[id] ?? HabitState(nextDue: .distantFuture) }
    package func strictness(_ id: HabitID) -> Strictness { data.prefs.strictness(id) }

    func update(_ id: HabitID, _ change: (inout HabitState) -> Void) {
        var st = state(id)
        change(&st)
        habits[id] = st
    }

    package func isActive(_ id: HabitID) -> Bool {
        switch phase {
        case let .bubble(h, _): return h == id
        case let .lock(h): return h == id
        case .session:
            switch id {
            case .water: return false
            case .reading: return true
            }
        default: return false
        }
    }

    package func isDue(_ id: HabitID) -> Bool { isActive(id) || queue.contains(id) }
}
