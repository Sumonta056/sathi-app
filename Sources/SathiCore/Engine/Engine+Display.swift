import Foundation

extension Engine {
    package var glassesToday: Double { stats.glasses(on: now, in: data.drinks) }
    package var readToday: Int { stats.readMinutes(on: now, in: data.reads) }

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
        guard data.prefs.waterEnabled else { return 0 }
        if isDue(.water) || water.snoozedUntil != nil { return 0 }
        let total = TimeInterval(data.prefs.waterIntervalMinutes) * Timing.minute
        return max(0, min(1, water.nextDue.timeIntervalSince(now) / total))
    }

    package func remaining(_ id: HabitID) -> TimeInterval {
        let st = state(id)
        var r = (st.snoozedUntil ?? st.nextDue).timeIntervalSince(now)
        let s = scheduler
        if id == .water && !s.inWaterHours(now) && !forced.contains(.water) {
            r = max(r, s.nextWaterStart(after: now).timeIntervalSince(now))
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
        if id == .water {
            if case .lock(.water) = phase { return .sad }
            if isDue(.water) || water.snoozedUntil != nil || waterLevel < Limits.lowWaterLevel { return .thirsty }
            return .happy
        }
        if phase == .session { return .reading }
        if isDue(.reading) || reading.snoozedUntil != nil { return .thirsty }
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
        id == .water
            ? glassesToday / max(1, data.prefs.dailyGoalGlasses)
            : Double(readToday) / Double(max(1, data.prefs.readingSessionMinutes))
    }

    package func subtitle(_ id: HabitID) -> String {
        if id == .water {
            return "\(Fmt.count(glassesToday)) of \(Int(data.prefs.dailyGoalGlasses)) glasses · \(streak(.water))-day streak"
        }
        let s = data.prefs.readingSessionMinutes
        return "\(min(readToday, s)) of \(s) min · \(streak(.reading))-day streak"
    }

    package func lockIsNext(_ id: HabitID) -> Bool {
        EscalationPolicy.lockIsNext(strictness(id), snoozes: state(id).snoozes)
    }

    package func snoozeLabel(_ id: HabitID) -> String {
        lockIsNext(id) ? "Last snooze" : "Snooze \(data.prefs.snoozeMinutes) min"
    }

    package func warnText(_ id: HabitID) -> String {
        lockIsNext(id)
            ? "No close button. Snooze again and \(id.buddy) pauses your screen."
            : "No close button. \(id.buddy) stays on top until you're done."
    }

    package var statusText: String {
        if pausedUntil != nil { return "Paused" }
        switch phase {
        case let .bubble(h, _): return h == .water ? "Drink!" : "Read!"
        case .lock: return "Locked"
        case .session: return Fmt.clock(sessionEnd.timeIntervalSince(now))
        case .celebrate: return "Done"
        case .idle: return focus.map { Fmt.short(remaining($0)) } ?? "Sathi"
        }
    }

    func updateStatus() {
        let level = (waterLevel * Limits.statusIconSteps).rounded() / Limits.statusIconSteps
        status.update(text: statusText, isBook: focus == .reading, iconLevel: level)
    }
}
