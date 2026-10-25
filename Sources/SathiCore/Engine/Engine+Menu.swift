import Foundation

extension Engine {
    package var greeting: String {
        Copywriter.greeting(at: now, name: data.prefs.general.name, calendar: calendar)
    }

    package var waterSeeYou: String {
        if !enabled(.water) { return "Nice one" }
        if pausedUntil != nil { return "See you after your break" }
        return Copywriter.seeYou(next: state(.water).nextDue, now: clock.now, calendar: calendar)
    }

    package var bestStreak: Int {
        HabitID.allCases.filter { enabled($0) }.map { streak($0) }.max() ?? 0
    }

    package func goalText(_ id: HabitID) -> GoalText {
        switch id {
        case .water:
            return GoalText(done: Fmt.count(glassesToday), rest: "of \(Int(data.prefs.water.dailyGoalGlasses)) glasses")
        case .reading:
            let s = data.prefs.reading.sessionMinutes
            return GoalText(done: "\(min(readToday, s))", rest: "of \(s) min")
        case .meditation:
            let r = rules(.meditation)
            let goal = Int(r.dailyGoal)
            let done = Int(r.total(on: now, data: data))
            return GoalText(done: "\(min(done, goal))", rest: "of \(goal) min")
        }
    }

    package var pauseEndText: String {
        guard let p = pausedUntil else { return "" }
        let isNextDay = p == calendar.startOfDay(for: p) && p > calendar.startOfDay(for: now)
        return isNextDay ? "tomorrow" : p.formatted(date: .omitted, time: .shortened)
    }

    package func pauseRestOfDay() {
        let today = calendar.startOfDay(for: clock.now)
        let midnight = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(Timing.day)
        let before = midnight.addingTimeInterval(-Timing.second)
        pausedUntil = midnight
        for id in HabitID.allCases {
            if case .bubble = activities[id] { close(id) }
            update(id) { $0.snoozedUntil = nil }
            guard enabled(id) else { continue }
            let r = rules(id)
            let due = r.nextSlot(after: before) ?? r.nextDue(now: before, lastDone: nil, doneToday: 0, skipToday: false)
            habits[id] = HabitState(nextDue: due)
        }
        requestTick()
    }
}
