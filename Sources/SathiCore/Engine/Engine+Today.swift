import Foundation

extension Engine {
    package var todayScreen: TodayScreen {
        let n = clock.now.wholeMinute
        return TodayScreen(
            dateLine: Copywriter.todayDateLine(n, calendar: calendar),
            greeting: Copywriter.greeting(at: n, name: data.prefs.general.name, calendar: calendar),
            now: todayNow(n),
            buddies: HabitID.allCases.map(todayBuddy),
            sofar: todaySoFar(n),
            comingUp: ComingUpList.make(items: comingUpItems(n), now: n, calendar: calendar)
        )
    }

    private func todayNow(_ n: Date) -> TodayNow {
        guard trackerPrefs.isOn else { return .off }
        let nextAsk = trackerNextPopup?.wholeMinute
        guard let r = runningActivity else { return .idle(nextAsk: nextAsk) }
        return .running(
            minutes: max(0, Int(n.timeIntervalSince(r.start) / Timing.minute)),
            text: r.text,
            category: r.category,
            since: r.start.wholeMinute,
            nextAsk: nextAsk
        )
    }

    private func todayBuddy(_ id: HabitID) -> TodayBuddy {
        let goal = todayGoal(id)
        return TodayBuddy(
            habit: id, total: goal.total, goal: goal.goal, unit: goal.unit,
            progress: min(1, progress(id)), status: todayStatus(id)
        )
    }

    private func todayGoal(_ id: HabitID) -> (total: String, goal: Int, unit: String) {
        let total = goalText(id).done
        switch id {
        case .water: return (total, Int(data.prefs.water.dailyGoalGlasses), Copywriter.todayGlassesUnit)
        case .reading: return (total, data.prefs.reading.sessionMinutes, Copywriter.todayMinutesUnit)
        case .meditation, .gym: return (total, Int(rules(id).dailyGoal), Copywriter.todayMinutesUnit)
        }
    }

    private func todayStatus(_ id: HabitID) -> TodayBuddyStatus {
        if !enabled(id) { return .off }
        if isOffToday(id) { return .dayOff }
        if goalMet(id), state(id).snoozedUntil == nil { return .met }
        guard let due = todayNextDue(id) else { return .noReminder }
        guard id == .gym else { return .next(due) }
        let g = gymProgress
        return .gymSession(g.current, of: g.sessions, due)
    }

    private func todayNextDue(_ id: HabitID) -> Date? {
        guard hasReminder(id) else { return nil }
        return clock.now.addingTimeInterval(remaining(id)).wholeMinute
    }

    private func todaySoFar(_ n: Date) -> TodaySoFar {
        guard trackerPrefs.isOn else { return .off }
        var day = activityDay(DayKey(n, calendar: calendar))
        if let r = runningActivity, let shown = day.running {
            day.running = r.activity(until: max(r.start, min(n, shown.end)))
        }
        let stats = ActivityDayStats(day)
        return TodaySoFar(
            isOn: true, hours: day.hours, segments: stats.segments, logged: stats.realWork,
            categories: Array(stats.categories.prefix(Limits.todayCategoryRows))
        )
    }

    private func comingUpItems(_ n: Date) -> [ComingUpItem] {
        var items: [ComingUpItem] = []
        if let ask = trackerNextPopup {
            let title = runningActivity == nil ? Copywriter.trackerWhatNow : Copywriter.todayStillOnIt
            items.append(ComingUpItem(kind: .trackerAsk, title: title, time: ask.wholeMinute))
        }
        for id in HabitID.allCases {
            switch todayStatus(id) {
            case let .next(due), let .gymSession(_, _, due):
                items.append(ComingUpItem(kind: .habit(id), title: Copywriter.todayItemName(id), time: due))
            case .met, .dayOff, .off, .noReminder:
                break
            }
        }
        for q in quickReminders {
            items.append(ComingUpItem(kind: .quick(q.id), title: q.text, time: q.fireDate.wholeMinute))
        }
        if let summary = nextDaySummary {
            items.append(ComingUpItem(kind: .daySummary, title: Copywriter.todayDaySummary, time: summary.wholeMinute))
        }
        return items
    }
}
