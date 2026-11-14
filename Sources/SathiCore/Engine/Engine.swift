import Combine
import Foundation

@MainActor
package final class Engine: ObservableObject {
    @Published package var data: Persisted {
        didSet {
            if streakInputsChanged(from: oldValue) { clearStreakCache() }
            if enabledHabits(oldValue.prefs) != enabledHabits(data.prefs) { allStreakCache = nil }
            if oldValue.prefs.scheduleKey != data.prefs.scheduleKey {
                let changed = Set(HabitID.allCases.filter { oldValue.prefs.scheduleKey($0) != data.prefs.scheduleKey($0) })
                reschedule(turnedOff: turnedOffToday(from: oldValue.prefs), changed: changed)
            }
            daySummaryPrefsChanged(from: oldValue.prefs.general)
            breathSoundChanged(from: oldValue.prefs.general)
            if oldValue.prefs.general.snoozeLimit != data.prefs.general.snoozeLimit { refreshIgnoreDeadlines() }
            if oldValue.prefs.timeBlock.display != data.prefs.timeBlock.display { blockDisplayChanged() }
            if oldValue.prefs.tracker != data.prefs.tracker { trackerPrefsChanged(from: oldValue.prefs.tracker) }
            if oldValue.prefs != data.prefs { store.savePrefs(data.prefs) }
            if oldValue.live != data.live { store.saveLive(data.live) }
        }
    }
    @Published package var now: Date
    @Published package var pausedUntil: Date? {
        didSet { if oldValue != pausedUntil { trackerBreakChanged(from: oldValue) } }
    }
    @Published package internal(set) var habits: [HabitID: HabitState]
    @Published package internal(set) var activities: [HabitID: HabitActivity] = [:] {
        didSet { if oldValue[.meditation] != activities[.meditation] { syncMeditationSession() } }
    }
    @Published package internal(set) var quickActivities: [UUID: QuickActivity] = [:]
    @Published package var celebration = Celebration()
    @Published package var isCelebrating = false
    @Published package internal(set) var gymIdea = 0
    @Published package internal(set) var finishedBlock: FinishedBlock?
    @Published package internal(set) var blockCheckInShowing = false
    @Published package internal(set) var waitingCalendarPick: String?
    @Published package internal(set) var calendarAccess: CalendarAccess
    @Published package internal(set) var mergeUndo: ManualMergeUndo?

    package let status = StatusModel()
    let store: StateStore
    let history: HistoryStore
    let clock: Clock
    let sound: SoundPlayer
    let presenter: ReminderPresenter
    let links: LinkOpener
    let calendarWriter: CalendarWriter
    let audio: SessionAudio
    let activityStore: ActivityStore
    let presence: PresenceMonitor
    let hotkeys: HotkeyRegistrar
    package let calendar: Calendar

    var timer: Timer?
    var isRunning = false
    var lastAccessRefresh: Date?
    var calendarChoicesCache: [CalendarChoice]?
    var forced: Set<HabitID> = []
    var celebrateToken = UUID()
    var streakCache: [HabitID: Int] = [:]
    var streakCacheDay: Date?
    var allStreakCache: AllStreakCache?
    var breathCueMark: Date?
    var minuteTickMark: Date?
    var storeRevision = 0
    var trackerRuntime = TrackerRuntime() {
        didSet { if oldValue.away != trackerRuntime.away { syncAwayDetails() } }
    }
    var trackerCalendarRuntime = TrackerCalendarRuntime()

    package init(
        store: StateStore,
        history: HistoryStore,
        clock: Clock,
        sound: SoundPlayer,
        presenter: ReminderPresenter,
        links: LinkOpener,
        calendar: Calendar = .current,
        calendarWriter: CalendarWriter,
        audio: SessionAudio = SilentSessionAudio(),
        activityStore: ActivityStore = NoActivityStore(),
        presence: PresenceMonitor = NoPresenceMonitor(),
        hotkeys: HotkeyRegistrar = NoHotkeyRegistrar()
    ) {
        let n = clock.now
        var loaded = Persisted()
        loaded.prefs = store.loadPrefs()
        loaded.live = store.loadLive()
        if loaded.live.gymMinutesSince == nil {
            loaded.live.gymMinutesSince = n.wholeSecond
            store.saveLive(loaded.live)
        }
        let window = history.events(from: Self.windowStart(now: n, calendar: calendar), to: n)
        loaded.events = GymLegacyMinutes.apply(window, since: loaded.live.gymMinutesSince)
        self.store = store
        self.history = history
        self.clock = clock
        self.sound = sound
        self.presenter = presenter
        self.links = links
        self.calendar = calendar
        self.calendarWriter = calendarWriter
        self.audio = audio
        self.activityStore = activityStore
        self.presence = presence
        self.hotkeys = hotkeys
        calendarAccess = calendarWriter.access
        data = loaded
        now = n
        habits = Dictionary(uniqueKeysWithValues: HabitID.allCases.map { id in
            let r = id.rules(loaded.prefs, calendar: calendar)
            let due = r.nextDue(
                now: n,
                lastDone: loaded.lastDone(id),
                doneToday: r.total(on: n, data: loaded),
                skipToday: Self.skipped(id, on: n, live: loaded.live, calendar: calendar)
            )
            return (id, HabitState(nextDue: due))
        })
        trackerRuntime.away = loaded.live.tracker.away
    }

    var stats: Stats { Stats(calendar: calendar) }

    func rules(_ id: HabitID) -> any HabitRules { id.rules(data.prefs, calendar: calendar) }

    func freshDue(_ id: HabitID, lastDone: Date?, skipToday: Bool = false) -> Date {
        let r = rules(id)
        let n = clock.now
        let skipped = skipToday || Self.skipped(id, on: n, live: data.live, calendar: calendar)
        return r.nextDue(now: n, lastDone: lastDone, doneToday: r.total(on: n, data: data), skipToday: skipped)
    }

    static func skipped(_ id: HabitID, on day: Date, live: LiveState, calendar: Calendar) -> Bool {
        live.streakReset[id.rawValue].map { calendar.isDate($0, inSameDayAs: day) } ?? false
    }

    package func enabled(_ id: HabitID) -> Bool { data.prefs.isEnabled(id) }
    package func state(_ id: HabitID) -> HabitState { habits[id] ?? HabitState(nextDue: .distantFuture) }
    package func strictness(_ id: HabitID) -> Strictness { data.prefs.strictness(id) }

    func update(_ id: HabitID, _ change: (inout HabitState) -> Void) {
        var st = state(id)
        change(&st)
        habits[id] = st
    }

    package func phase(_ id: HabitID) -> Phase { activities[id]?.phase ?? .idle }
    package func isActive(_ id: HabitID) -> Bool { activities[id] != nil }

    func storesChanged() {
        storeRevision += 1
        objectWillChange.send()
    }
}
