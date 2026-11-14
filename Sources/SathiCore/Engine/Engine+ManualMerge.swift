import Foundation

package enum ManualMergeResult: Equatable {
    case merged(ActivityID)
    case blocked(ManualMergeBlock)
    case calendarFailed
}

extension Engine {
    package func mergeCheck(_ ids: Set<ActivityID>) -> ManualMergeCheck {
        let found = activityStore.allActivities().filter { ids.contains($0.id) }
        var days: [Date] = []
        for row in found {
            let day = calendar.startOfDay(for: row.start)
            if !days.contains(day) { days.append(day) }
        }
        let rows = days.flatMap(storedActivities)
        return ManualMergeCheck.check(ids, dayRows: rows, calendar: calendar)
    }

    @discardableResult
    package func mergeActivities(_ ids: Set<ActivityID>) -> ManualMergeResult {
        switch mergeCheck(ids) {
        case let .blocked(reason):
            return .blocked(reason)
        case let .ok(plan):
            guard let merged = mergedEvents(plan) else { return .calendarFailed }
            let removing = Set(plan.rows.map(\.id) + plan.removedAway.map(\.id))
            replaceDayRows(removing: removing, with: merged)
            return .merged(merged.id)
        }
    }

    func replaceDayRows(removing: Set<ActivityID>, with row: Activity) {
        var month = activityStore.month(MonthKey(row.start, calendar: calendar))
        month.items.removeAll { removing.contains($0.id) }
        month.items.append(row)
        month.items.sort { $0.start < $1.start }
        activityStore.save(month)
        storesChanged()
    }
}
