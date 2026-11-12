import Foundation

package enum BuddyDayState: Equatable, Sendable {
    case met
    case some
    case none
    case off
    case future
}

package struct BuddyDayJudge: Sendable {
    let calendar: Calendar
    let prefs: Prefs
    let now: Date
    private let goals: [HabitID: Double]
    private let totals: [HabitID: [Date: Double]]

    package init(calendar: Calendar, prefs: Prefs, now: Date, events: [HistoryEvent], resets: [HabitID: Date] = [:]) {
        let gregorian = Calendar.gregorian(in: calendar.timeZone)
        self.calendar = gregorian
        self.prefs = prefs
        self.now = now
        goals = Dictionary(uniqueKeysWithValues: HabitID.allCases.map { ($0, $0.rules(prefs, calendar: gregorian).dailyGoal) })
        var sums: [HabitID: [Date: Double]] = [:]
        for e in events where e.kind == .done && e.date > (resets[e.habit] ?? .distantPast) {
            sums[e.habit, default: [:]][gregorian.startOfDay(for: e.date), default: 0] += e.amount
        }
        totals = sums
    }

    package var buddies: [HabitID] {
        HabitID.allCases.filter { prefs.isEnabled($0) && goal($0) > 0 }
    }

    package func goal(_ id: HabitID) -> Double {
        goals[id] ?? 0
    }

    package func total(_ id: HabitID, on day: Date) -> Double {
        totals[id]?[calendar.startOfDay(for: day)] ?? 0
    }

    package func isMet(_ id: HabitID, on day: Date) -> Bool {
        goal(id) > 0 && total(id, on: day) >= goal(id)
    }

    package func isOn(_ id: HabitID, on day: Date) -> Bool {
        prefs.days(id).isOn(day, calendar: calendar)
    }

    package func isPast(_ day: Date) -> Bool {
        calendar.startOfDay(for: day) <= now
    }

    package func isCounted(_ id: HabitID, on day: Date) -> Bool {
        isPast(day) && (isMet(id, on: day) || isOn(id, on: day))
    }

    package func state(_ id: HabitID, on day: Date) -> BuddyDayState {
        if !isPast(day) { return .future }
        if isMet(id, on: day) { return .met }
        if !isOn(id, on: day) { return .off }
        return total(id, on: day) > 0 ? .some : .none
    }

    package func isStreakDay(_ day: Date) -> Bool? {
        guard isPast(day) else { return nil }
        let counted = buddies.filter { isCounted($0, on: day) }
        guard !counted.isEmpty else { return nil }
        return counted.allSatisfy { isMet($0, on: day) }
    }
}
