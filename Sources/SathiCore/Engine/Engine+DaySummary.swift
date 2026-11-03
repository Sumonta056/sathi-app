import Foundation

extension Engine {
    package var daySummary: DaySummary {
        let day = data.live.lastDaySummary?.start(in: calendar) ?? clock.now
        return DaySummary(rows: HabitID.allCases.map { id in
            DaySummaryRow(id: id, status: summaryStatus(id, on: day), streak: streak(id))
        })
    }

    package func closeDaySummary() {
        presenter.closeDaySummary()
    }

    func daySummaryPrefsChanged(from old: GeneralPrefs) {
        let g = data.prefs.general
        guard old.daySummaryOn != g.daySummaryOn || old.daySummaryMinutes != g.daySummaryMinutes else { return }
        if old.daySummaryOn && !g.daySummaryOn { presenter.closeDaySummary() }
        requestTick()
    }

    var isDaySummaryDue: Bool {
        let n = clock.now
        guard data.prefs.general.daySummaryOn, data.live.lastDaySummary != DayKey(n, calendar: calendar) else { return false }
        return n >= daySummaryTime(on: n)
    }

    var nextDaySummary: Date? {
        guard data.prefs.general.daySummaryOn else { return nil }
        let n = clock.now
        let todays = daySummaryTime(on: n)
        if todays > n && data.live.lastDaySummary != DayKey(n, calendar: calendar) { return todays }
        return daySummaryTime(on: calendar.nextDay(after: n))
    }

    func showDaySummaryIfDue() {
        guard isDaySummaryDue else { return }
        data.live.lastDaySummary = DayKey(clock.now, calendar: calendar)
        presenter.showDaySummary()
    }

    private func daySummaryTime(on day: Date) -> Date {
        DayClock(calendar: calendar).at(data.prefs.general.daySummaryMinutes, on: day)
    }

    private func summaryStatus(_ id: HabitID, on day: Date) -> DaySummaryStatus {
        guard enabled(id) else { return .off }
        let r = rules(id)
        let status = DaySummaryStatus.progress(done: r.total(on: day, data: data), goal: r.dailyGoal)
        return !data.prefs.days(id).isOn(day, calendar: calendar) && !status.isMet ? .dayOff : status
    }
}
