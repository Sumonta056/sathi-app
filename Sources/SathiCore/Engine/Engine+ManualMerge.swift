import Foundation

package enum ManualMergeResult: Equatable {
    case merged(ActivityID)
    case blocked(ManualMergeBlock)
    case calendarFailed
    case calendarPartlyChanged
}

extension Engine {
    package func mergeCheck(_ ids: Set<ActivityID>) -> ManualMergeCheck {
        defer { activityStore.releaseUnused() }
        var left = ids
        var days: [Date] = []
        for key in activityStore.savedMonths().sorted(by: >) where !left.isEmpty {
            for row in activityStore.month(key).items where left.remove(row.id) != nil {
                let day = calendar.startOfDay(for: row.start)
                if !days.contains(day) { days.append(day) }
            }
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
            let merged: Activity
            switch mergedEvents(plan) {
            case let .ready(row): merged = row
            case .failed: return .calendarFailed
            case .partlyChanged: return .calendarPartlyChanged
            }
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
