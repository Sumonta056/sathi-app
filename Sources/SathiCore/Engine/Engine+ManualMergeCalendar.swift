import Foundation

enum ManualMergeEvents {
    case ready(Activity)
    case failed
    case partlyChanged
}

extension Engine {
    func mergedEvents(_ plan: ManualMergePlan) -> ManualMergeEvents {
        var merged = plan.merged
        guard let kept = plan.keptEventRow, let eventID = kept.eventID else { return .ready(merged) }
        guard let calendarID = kept.calendarID else { return .failed }
        let ids = [eventID] + plan.droppedEventRows.compactMap(\.eventID)
        guard !ids.contains(where: calendarWriter.isLocked) else { return .failed }
        let draft = CalendarEventDraft(calendarID: calendarID, title: merged.text, start: merged.start, end: merged.end)
        guard case let .saved(saved) = calendarWriter.update(eventID: eventID, draft: draft) else { return .failed }
        if !saved.isEmpty { merged.eventID = saved }
        var deleted: [Activity] = []
        for row in plan.droppedEventRows {
            guard let id = row.eventID, calendarWriter.delete(eventID: id) == .deleted else {
                let clean = restoreEvents(kept: kept, eventID: merged.eventID ?? eventID, deleted: deleted)
                return clean ? .failed : .partlyChanged
            }
            deleted.append(row)
        }
        return .ready(merged)
    }

    private func restoreEvents(kept: Activity, eventID: String, deleted: [Activity]) -> Bool {
        var clean = true
        if let calendarID = kept.calendarID {
            let back = CalendarEventDraft(calendarID: calendarID, title: kept.text, start: kept.start, end: kept.end)
            if case let .saved(id) = calendarWriter.update(eventID: eventID, draft: back) {
                if !id.isEmpty, id != kept.eventID { replaceStoredActivity(kept.id) { var a = $0; a.eventID = id; return a } }
            } else {
                clean = false
            }
        }
        for row in deleted {
            var newID: String?
            if let calendarID = row.calendarID {
                let draft = CalendarEventDraft(calendarID: calendarID, title: row.text, start: row.start, end: row.end)
                if case let .saved(id) = calendarWriter.save(draft), !id.isEmpty { newID = id }
            }
            if newID == nil { clean = false }
            replaceStoredActivity(row.id) { var a = $0; a.eventID = newID; return a }
        }
        return clean
    }
}
