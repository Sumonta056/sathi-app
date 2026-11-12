import Foundation

extension Engine {
    func mergeOldRowsOnce() {
        guard !data.prefs.tracker.mergedOldRows else { return }
        let keep = rowsInAwayUndo()
        var done = true
        for key in activityStore.savedMonths() {
            guard let merged = StoredRowsMerge.merged(activityStore.month(key), calendar: calendar, keep: keep) else { continue }
            guard activityStore.backup(key) else {
                done = false
                continue
            }
            activityStore.save(merged)
        }
        if done { data.prefs.tracker.mergedOldRows = true }
    }

    private func rowsInAwayUndo() -> Set<ActivityID> {
        let away = data.live.tracker.away
        return Set(away.awayItems + away.loggedWhileAway.map(\.id) + [away.endedMergedInto?.id].compactMap { $0 })
    }
}
