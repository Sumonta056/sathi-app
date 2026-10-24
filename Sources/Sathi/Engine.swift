import SwiftUI
import AppKit

enum Level: Equatable { case nudge, persist }

enum Phase: Equatable {
    case idle
    case bubble(HabitID, Level)
    case lock(HabitID)
    case session
    case celebrate
}

struct HabitState: Equatable {
    var nextDue: Date
    var snoozes = 0
    var snoozedUntil: Date? = nil
}

struct Copy: Equatable {
    var title = ""
    var body = ""
}

struct Celebration: Equatable {
    var id: HabitID = .water
    var amount: Double = 1
    var title = ""
}

/// The scheduler. Ticks once a second, queues due habits, and escalates:
/// nudge -> persist (stays on top) -> lock (strict only).
@MainActor
final class Engine: ObservableObject {
    static let shared = Engine()

    @Published var data: Persisted {
        didSet {
            if oldValue.prefs.scheduleKey != data.prefs.scheduleKey { reschedule() }
            save()
        }
    }
    @Published var now = Date()
    @Published var phase: Phase = .idle
    @Published var pausedUntil: Date?
    @Published var water: HabitState
    @Published var reading: HabitState
    @Published var queue: [HabitID] = []
    @Published var copy = Copy()
    @Published var celebration = Celebration()
    @Published var ignoreDeadline = Date()
    @Published var sessionStart = Date()
    @Published var sessionEnd = Date()
    @Published var statusText = "Sathi"
    @Published var statusIcon: NSImage = Engine.dropIcon(level: 1)
    @Published var statusIsBook = false

    let ui = UIController()
    private var timer: Timer?
    private var forced: Set<HabitID> = []
    private var celebrateToken = UUID()
    private var lastIconLevel: Double = -1
    private static let storeKey = "sathi.state.v1"

    init() {
        var loaded = Persisted()
        if let raw = UserDefaults.standard.data(forKey: Engine.storeKey),
           let decoded = try? JSONDecoder().decode(Persisted.self, from: raw) {
            loaded = decoded
        }
        let n = Date()
        self.data = loaded
        self.water = HabitState(nextDue: n)
        self.reading = HabitState(nextDue: n)
        self.water.nextDue = nextWaterDue(after: loaded.lastWaterDone ?? n)
        self.reading.nextDue = nextReadingDue(skipToday: false)
        ui.engine = self
    }

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    // MARK: - Time helpers

    private var cal: Calendar { Calendar.current }

    func at(_ minutes: Int, on day: Date) -> Date {
        cal.date(byAdding: .minute, value: minutes, to: cal.startOfDay(for: day)) ?? day
    }

    func minutesOfDay(_ d: Date) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    func inWaterHours(_ d: Date) -> Bool {
        let m = minutesOfDay(d)
        return m >= data.prefs.waterStartMinutes && m < data.prefs.waterEndMinutes
    }

    func nextWaterDue(after base: Date) -> Date {
        let p = data.prefs
        var c = base.addingTimeInterval(TimeInterval(p.waterIntervalMinutes * 60))
        let m = minutesOfDay(c)
        if m < p.waterStartMinutes {
            c = at(p.waterStartMinutes, on: c)
        } else if m >= p.waterEndMinutes {
            c = at(p.waterStartMinutes, on: c.addingTimeInterval(86400))
        }
        return c
    }

    func nextReadingDue(skipToday: Bool) -> Date {
        let n = Date()
        if skipToday || readMinutes(on: n) >= data.prefs.readingSessionMinutes {
            return at(data.prefs.readingTimeMinutes, on: n.addingTimeInterval(86400))
        }
        return at(data.prefs.readingTimeMinutes, on: n)
    }

    // MARK: - Stats

    func glasses(on day: Date) -> Double {
        data.drinks.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.glasses }
    }

    func readMinutes(on day: Date) -> Int {
        data.reads.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.minutes }
    }

    var glassesToday: Double { glasses(on: now) }
    var readToday: Int { readMinutes(on: now) }

    func streak(_ id: HabitID) -> Int {
        let reset = data.streakReset[id.rawValue] ?? .distantPast
        let calendar = cal
        let drinks = data.drinks.filter { $0.date > reset }
        let reads = data.reads.filter { $0.date > reset }
        let goal = data.prefs.dailyGoalGlasses
        let session = data.prefs.readingSessionMinutes
        func met(_ d: Date) -> Bool {
            if id == .water {
                return drinks.filter { calendar.isDate($0.date, inSameDayAs: d) }.reduce(0) { $0 + $1.glasses } >= goal
            }
            return reads.filter { calendar.isDate($0.date, inSameDayAs: d) }.reduce(0) { $0 + $1.minutes } >= session
        }
        var day = now
        var count = met(day) ? 1 : 0
        for _ in 0..<365 {
            day = day.addingTimeInterval(-86400)
            if met(day) { count += 1 } else { break }
        }
        return count
    }

    // MARK: - State helpers

    func enabled(_ id: HabitID) -> Bool { id == .water ? data.prefs.waterEnabled : data.prefs.readingEnabled }
    func state(_ id: HabitID) -> HabitState { id == .water ? water : reading }
    func strictness(_ id: HabitID) -> Strictness { id == .water ? data.prefs.waterStrictness : data.prefs.readingStrictness }

    func update(_ id: HabitID, _ f: (inout HabitState) -> Void) {
        if id == .water { f(&water) } else { f(&reading) }
    }

    func isActive(_ id: HabitID) -> Bool {
        switch phase {
        case .bubble(let h, _): return h == id
        case .lock(let h): return h == id
        case .session: return id == .reading
        default: return false
        }
    }

    // MARK: - Loop

    func tick() {
        now = Date()
        if let p = pausedUntil, now >= p { pausedUntil = nil }

        if pausedUntil == nil {
            for id in HabitID.allCases where enabled(id) {
                if isActive(id) || queue.contains(id) { continue }
                let st = state(id)
                let due: Bool
                if let s = st.snoozedUntil { due = now >= s } else { due = now >= st.nextDue }
                if due && (id != .water || forced.contains(id) || inWaterHours(now)) {
                    queue.append(id)
                }
            }
        }

        switch phase {
        case .bubble:
            if now >= ignoreDeadline { snooze() }
        case .session:
            if now >= sessionEnd { finishSession() }
        default:
            break
        }

        if phase == .idle, pausedUntil == nil, !queue.isEmpty {
            present(queue.removeFirst())
        }
        updateStatus()
    }

    private func present(_ id: HabitID) {
        forced.remove(id)
        let st = state(id)
        switch strictness(id) {
        case .friendly:
            showBubble(id, .nudge)
        case .persistent:
            showBubble(id, st.snoozes == 0 ? .nudge : .persist)
        case .strict:
            if st.snoozes == 0 { showBubble(id, .nudge) }
            else if st.snoozes == 1 { showBubble(id, .persist) }
            else { showLock(id) }
        }
    }

    private func showBubble(_ id: HabitID, _ level: Level) {
        copy = Copywriter.pick(id, level, name: data.prefs.name)
        ignoreDeadline = Date().addingTimeInterval(TimeInterval(data.prefs.ignoreMinutes * 60))
        phase = .bubble(id, level)
        ui.showBubble(id, level)
        play(level == .persist ? "Ping" : (id == .water ? "Glass" : "Purr"))
    }

    private func showLock(_ id: HabitID) {
        phase = .lock(id)
        ui.showLock(id)
        play("Sosumi")
    }

    // MARK: - Actions

    func snooze() {
        guard case .bubble(let id, _) = phase else { return }
        let until = Date().addingTimeInterval(TimeInterval(data.prefs.snoozeMinutes * 60))
        update(id) { st in
            st.snoozes += 1
            st.snoozedUntil = until
        }
        ui.closeBubble()
        phase = .idle
    }

    func logWater(_ amount: Double) {
        let g = max(0.25, (amount * 4).rounded() / 4)
        let n = Date()
        data.drinks.append(DrinkEntry(date: n, glasses: g))
        data.lastWaterDone = n
        prune()
        water = HabitState(nextDue: nextWaterDue(after: n))
        queue.removeAll { $0 == .water }
        if isActive(.water) {
            ui.closeBubble()
            ui.closeLock()
            phase = .idle
        }
        if phase == .idle { celebrate(.water, g) } else { play("Glass") }
    }

    func logBottle(newLevel: Double) {
        let level = max(0, min(1, newLevel))
        let amount = (data.bottleLevel - level) * data.prefs.bottleSizeGlasses
        data.bottleLevel = level
        logWater(amount)
    }

    func refillBottle() { data.bottleLevel = 1 }

    func startReading() {
        guard phase == .idle || isActive(.reading) else { NSSound.beep(); return }
        ui.closeBubble()
        ui.closeLock()
        queue.removeAll { $0 == .reading }
        sessionStart = Date()
        sessionEnd = sessionStart.addingTimeInterval(TimeInterval(data.prefs.readingSessionMinutes * 60))
        phase = .session
        ui.showSession()
        play("Purr")
    }

    func finishSession() {
        let mins = data.prefs.readingSessionMinutes
        data.reads.append(ReadEntry(date: Date(), minutes: mins))
        prune()
        reading = HabitState(nextDue: nextReadingDue(skipToday: false))
        ui.closeSession()
        phase = .idle
        celebrate(.reading, Double(mins))
    }

    func stopSession() {
        ui.closeSession()
        let until = Date().addingTimeInterval(TimeInterval(data.prefs.snoozeMinutes * 60))
        update(.reading) { st in
            st.snoozes += 1
            st.snoozedUntil = until
        }
        phase = .idle
    }

    func lockConfirmed(_ id: HabitID) {
        if id == .water { logWater(1) } else { startReading() }
    }

    func emergencySkip(_ id: HabitID) {
        data.streakReset[id.rawValue] = Date()
        if id == .water {
            water = HabitState(nextDue: nextWaterDue(after: Date()))
        } else {
            reading = HabitState(nextDue: nextReadingDue(skipToday: true))
        }
        ui.closeLock()
        phase = .idle
    }

    private func celebrate(_ id: HabitID, _ amount: Double) {
        let titles = id == .water
            ? ["Ahh, that's better.", "Fota is happy again.", "Refilled."]
            : ["Chapter done.", "Boi is proud of you.", "Nice reading."]
        celebration = Celebration(id: id, amount: amount, title: titles.randomElement() ?? titles[0])
        phase = .celebrate
        ui.showCelebrate()
        play("Hero")
        let token = UUID()
        celebrateToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            guard let self, self.celebrateToken == token else { return }
            self.endCelebrate()
        }
    }

    func endCelebrate() {
        guard phase == .celebrate else { return }
        ui.closeCelebrate()
        phase = .idle
    }

    /// Show a reminder right now (used by "Try it" buttons).
    func trigger(_ id: HabitID) {
        pausedUntil = nil
        guard enabled(id), !isActive(id) else { return }
        forced.insert(id)
        update(id) { st in
            st.snoozedUntil = nil
            st.nextDue = Date()
        }
        if phase == .celebrate { endCelebrate() }
        tick()
    }

    func pause(hours: Double) { pausedUntil = Date().addingTimeInterval(hours * 3600) }
    func resume() { pausedUntil = nil }

    private func reschedule() {
        let n = Date()
        if !isActive(.water) && water.snoozedUntil == nil {
            water.nextDue = nextWaterDue(after: data.lastWaterDone ?? n)
        }
        if !isActive(.reading) && reading.snoozedUntil == nil {
            reading.nextDue = nextReadingDue(skipToday: false)
        }
        queue.removeAll { !enabled($0) }
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: Engine.storeKey)
        }
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-90 * 86400)
        if data.drinks.contains(where: { $0.date < cutoff }) { data.drinks.removeAll { $0.date < cutoff } }
        if data.reads.contains(where: { $0.date < cutoff }) { data.reads.removeAll { $0.date < cutoff } }
    }

    func play(_ name: String) {
        guard data.prefs.soundOn else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Display helpers

    var waterLevel: Double {
        guard data.prefs.waterEnabled else { return 0 }
        if isActive(.water) || queue.contains(.water) || water.snoozedUntil != nil { return 0 }
        let total = TimeInterval(data.prefs.waterIntervalMinutes * 60)
        return max(0, min(1, water.nextDue.timeIntervalSince(now) / total))
    }

    func remaining(_ id: HabitID) -> TimeInterval {
        let st = state(id)
        var r = (st.snoozedUntil ?? st.nextDue).timeIntervalSince(now)
        if id == .water && !inWaterHours(now) && !forced.contains(.water) {
            let startToday = at(data.prefs.waterStartMinutes, on: now)
            let nextStart = startToday > now ? startToday : at(data.prefs.waterStartMinutes, on: now.addingTimeInterval(86400))
            r = max(r, nextStart.timeIntervalSince(now))
        }
        return r
    }

    var focus: HabitID? {
        switch phase {
        case .bubble(let h, _): return h
        case .lock(let h): return h
        case .session: return .reading
        default: break
        }
        let ids = HabitID.allCases.filter { enabled($0) }
        return ids.min { remaining($0) < remaining($1) }
    }

    private func updateStatus() {
        let f = focus
        let text: String
        if pausedUntil != nil {
            text = "Paused"
        } else {
            switch phase {
            case .bubble(let h, _): text = h == .water ? "Drink!" : "Read!"
            case .lock: text = "Locked"
            case .session: text = Fmt.clock(sessionEnd.timeIntervalSince(now))
            case .celebrate: text = "Done"
            case .idle: text = f.map { Fmt.short(remaining($0)) } ?? "Sathi"
            }
        }
        if statusText != text { statusText = text }
        let isBook = f == .reading
        if statusIsBook != isBook { statusIsBook = isBook }
        let lvl = (waterLevel * 20).rounded() / 20
        if lvl != lastIconLevel {
            lastIconLevel = lvl
            statusIcon = Engine.dropIcon(level: lvl)
        }
    }

    func mood(_ id: HabitID) -> Mood {
        if id == .water {
            if case .lock(.water) = phase { return .sad }
            if isActive(.water) || queue.contains(.water) || water.snoozedUntil != nil || waterLevel < 0.25 { return .thirsty }
            return .happy
        }
        if phase == .session { return .reading }
        if isActive(.reading) || queue.contains(.reading) || reading.snoozedUntil != nil { return .thirsty }
        return .happy
    }

    func pill(_ id: HabitID) -> String {
        if !enabled(id) { return "Off" }
        if isActive(id) { return phase == .session ? "Reading…" : "Due now" }
        if queue.contains(id) { return "Queued" }
        if pausedUntil != nil { return "Paused" }
        let r = remaining(id)
        if state(id).snoozedUntil != nil { return "Snoozed · " + Fmt.short(r) }
        if r > 3 * 3600 { return "at " + now.addingTimeInterval(r).formatted(date: .omitted, time: .shortened) }
        return "in " + Fmt.short(r)
    }

    func progress(_ id: HabitID) -> Double {
        id == .water
            ? glassesToday / max(1, data.prefs.dailyGoalGlasses)
            : Double(readToday) / Double(max(1, data.prefs.readingSessionMinutes))
    }

    func subtitle(_ id: HabitID) -> String {
        if id == .water {
            return "\(Fmt.count(glassesToday)) of \(Int(data.prefs.dailyGoalGlasses)) glasses · \(streak(.water))-day streak"
        }
        let s = data.prefs.readingSessionMinutes
        return "\(min(readToday, s)) of \(s) min · \(streak(.reading))-day streak"
    }

    func lockIsNext(_ id: HabitID) -> Bool { strictness(id) == .strict && state(id).snoozes >= 1 }

    func snoozeLabel(_ id: HabitID) -> String {
        lockIsNext(id) ? "Last snooze" : "Snooze \(data.prefs.snoozeMinutes) min"
    }

    func warnText(_ id: HabitID) -> String {
        lockIsNext(id)
            ? "No close button. Snooze again and \(id.buddy) pauses your screen."
            : "No close button. \(id.buddy) stays on top until you're done."
    }

    /// Template image for the menu bar: a drop that drains as the next glass approaches.
    nonisolated static func dropIcon(level: Double) -> NSImage {
        let img = NSImage(size: NSSize(width: 14, height: 17), flipped: true) { rect in
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }
            let s = rect.height / 124
            cg.translateBy(x: (rect.width - 100 * s) / 2, y: 0)
            cg.scaleBy(x: s, y: s)
            let drop = BuddyPaths.drop().cgPath
            cg.setFillColor(NSColor.black.withAlphaComponent(0.2).cgColor)
            cg.addPath(drop)
            cg.fillPath()
            cg.saveGState()
            cg.addPath(drop)
            cg.clip()
            cg.setFillColor(NSColor.black.cgColor)
            let top = 116 - CGFloat(level) * 112
            cg.fill(CGRect(x: 0, y: top, width: 100, height: 124 - top))
            cg.restoreGState()
            cg.setStrokeColor(NSColor.black.cgColor)
            cg.setLineWidth(10)
            cg.addPath(drop)
            cg.strokePath()
            return true
        }
        img.isTemplate = true
        return img
    }
}
