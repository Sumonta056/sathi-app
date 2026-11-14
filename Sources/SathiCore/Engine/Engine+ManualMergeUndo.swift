import Foundation

package enum ManualMergeUndoResult: Equatable {
    case restored
    case restoredCalendarFailed
    case gone
}

extension Engine {
    package func undoMerge() -> ManualMergeUndoResult {
        guard let undo = mergeUndo else { return .gone }
        mergeUndo = nil
        guard clock.now < undo.until, storedActivity(undo.merged.id) == undo.merged else { return .gone }
        var rows = undo.before
        var clean = true
        if let kept = undo.keptEventRow, let eventID = undo.merged.eventID {
            let newID = movedBack(kept, eventID: eventID)
            if newID == nil { clean = false }
            if let newID, newID != kept.eventID { setEventID(newID, of: kept.id, in: &rows) }
        }
        for row in undo.deletedEventRows {
            let newID = savedAgain(row)
            if newID == nil { clean = false }
            setEventID(newID, of: row.id, in: &rows)
        }
        restoreRows(rows, replacing: undo.merged)
        return clean ? .restored : .restoredCalendarFailed
    }

    func recordMergeUndo(_ plan: ManualMergePlan, merged: Activity) {
        mergeUndo = ManualMergeUndo(
            merged: merged,
            before: (plan.rows + plan.removedAway).sorted { $0.start < $1.start },
            keptEventRow: plan.keptEventRow,
            deletedEventRows: plan.droppedEventRows,
            until: clock.now.addingTimeInterval(Timing.mergeUndoShow)
        )
        requestTick()
    }

    func clearMergeUndo() {
        if mergeUndo != nil { mergeUndo = nil }
    }

    func expireMergeUndo() {
        if let undo = mergeUndo, now >= undo.until { mergeUndo = nil }
    }

    var mergeDeadlines: [Date] { mergeUndo.map { [$0.until] } ?? [] }

    private func movedBack(_ kept: Activity, eventID: String) -> String? {
        guard let calendarID = kept.calendarID else { return nil }
        let draft = CalendarEventDraft(calendarID: calendarID, title: kept.text, start: kept.start, end: kept.end)
        guard case let .saved(id) = calendarWriter.update(eventID: eventID, draft: draft) else { return nil }
        return id.isEmpty ? eventID : id
    }

    private func savedAgain(_ row: Activity) -> String? {
        guard let calendarID = row.calendarID else { return nil }
        let draft = CalendarEventDraft(calendarID: calendarID, title: row.text, start: row.start, end: row.end)
        guard case let .saved(id) = calendarWriter.save(draft), !id.isEmpty else { return nil }
        return id
    }

    private func setEventID(_ id: String?, of rowID: ActivityID, in rows: inout [Activity]) {
        guard let i = rows.firstIndex(where: { $0.id == rowID }) else { return }
        rows[i].eventID = id
    }

    private func restoreRows(_ rows: [Activity], replacing merged: Activity) {
        var month = activityStore.month(MonthKey(merged.start, calendar: calendar))
        month.items.removeAll { $0.id == merged.id }
        month.items.append(contentsOf: rows)
        month.items.sort { $0.start < $1.start }
        activityStore.save(month)
        storesChanged()
    }
}
