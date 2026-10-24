import Foundation

extension Engine {
    package var glassesToday: Double { stats.total(.water, on: now, in: data.events) }
    package var readToday: Int { Int(stats.total(.reading, on: now, in: data.events)) }

    package func streak(_ id: HabitID) -> Int {
        let today = calendar.startOfDay(for: now)
        if streakCacheDay != today {
            streakCache.removeAll()
            streakCacheDay = today
        }
        if let cached = streakCache[id] { return cached }
        let value = stats.streak(id, data: data, now: now)
        streakCache[id] = value
        return value
    }

    package var waterLevel: Double {
        guard data.prefs.water.enabled else { return 0 }
        let st = state(.water)
        if isDue(.water) || st.snoozedUntil != nil { return 0 }
        let total = TimeInterval(data.prefs.water.intervalMinutes) * Timing.minute
        return max(0, min(1, st.nextDue.timeIntervalSince(now) / total))
    }

    package func remaining(_ id: HabitID) -> TimeInterval {
        let st = state(id)
        var r = (st.snoozedUntil ?? st.nextDue).timeIntervalSince(now)
        let rule = rules(id)
        if !rule.isActiveTime(now) && !forced.contains(id) {
            r = max(r, rule.nextActiveStart(after: now).timeIntervalSince(now))
        }
        return r
    }

    package var focus: HabitID? {
        switch phase {
        case let .bubble(h, _): return h
        case let .lock(h): return h
        case .session: return .reading
        default: break
        }
        return HabitID.allCases.filter { enabled($0) }.min { remaining($0) < remaining($1) }
    }

    package func mood(_ id: HabitID) -> Mood {
        let waiting = isDue(id) || state(id).snoozedUntil != nil
        switch id {
        case .water:
            if case .lock(.water) = phase { return .sad }
            if waiting || waterLevel < Limits.lowWaterLevel { return .thirsty }
        case .reading:
            if phase == .session { return .reading }
            if waiting { return .thirsty }
        }
        return .happy
    }

    package func pill(_ id: HabitID) -> String {
        if !enabled(id) { return "Off" }
        if isActive(id) { return phase == .session ? "Reading…" : "Due now" }
        if queue.contains(id) { return "Queued" }
        if pausedUntil != nil { return "Paused" }
        let r = remaining(id)
        if state(id).snoozedUntil != nil { return "Snoozed · " + Fmt.short(r) }
        if r > Limits.absoluteTimeThreshold {
            return "at " + now.addingTimeInterval(r).formatted(date: .omitted, time: .shortened)
        }
        return "in " + Fmt.short(r)
    }

    package func progress(_ id: HabitID) -> Double {
        let r = rules(id)
        return r.total(on: now, data: data) / max(1, r.dailyGoal)
    }

    package func subtitle(_ id: HabitID) -> String {
        switch id {
        case .water:
            return "\(Fmt.count(glassesToday)) of \(Int(data.prefs.water.dailyGoalGlasses)) glasses · \(streak(.water))-day streak"
        case .reading:
            let s = data.prefs.reading.sessionMinutes
            return "\(min(readToday, s)) of \(s) min · \(streak(.reading))-day streak"
        }
    }

    package func lockIsNext(_ id: HabitID) -> Bool {
        EscalationPolicy.lockIsNext(strictness(id), snoozes: state(id).snoozes)
    }

    package func snoozeLabel(_ id: HabitID) -> String {
        lockIsNext(id) ? "Last snooze" : "Snooze \(data.prefs.general.snoozeMinutes) min"
    }

    package func warnText(_ id: HabitID) -> String {
        lockIsNext(id)
            ? "No close button. Snooze again and \(id.buddy) pauses your screen."
            : "No close button. \(id.buddy) stays on top until you're done."
    }

    package var statusText: String {
        if pausedUntil != nil { return "Paused" }
        switch phase {
        case let .bubble(h, _): return Self.callToAction(h)
        case .lock: return "Locked"
        case .session: return Fmt.clock(sessionEnd.timeIntervalSince(now))
        case .celebrate: return "Done"
        case .idle: return focus.map { Fmt.short(remaining($0)) } ?? "Sathi"
        }
    }

    private static func callToAction(_ id: HabitID) -> String {
        switch id {
        case .water: return "Drink!"
        case .reading: return "Read!"
        }
    }

    func updateStatus() {
        let level = (waterLevel * Limits.statusIconSteps).rounded() / Limits.statusIconSteps
        status.update(text: statusText, isBook: focus == .reading, iconLevel: level)
    }
}
