import Foundation

extension Engine {
    func mergedEvents(_ plan: ManualMergePlan) -> Activity? {
        var merged = plan.merged
        guard let kept = plan.keptEventRow, let eventID = kept.eventID,
              let calendarID = kept.calendarID else { return merged }
        let draft = CalendarEventDraft(calendarID: calendarID, title: merged.text, start: merged.start, end: merged.end)
        guard case let .saved(saved) = calendarWriter.update(eventID: eventID, draft: draft) else { return nil }
        if !saved.isEmpty { merged.eventID = saved }
        var deleted: [Activity] = []
        for row in plan.droppedEventRows {
            guard let id = row.eventID, calendarWriter.delete(eventID: id) else {
                restoreEvents(kept: kept, eventID: merged.eventID ?? eventID, deleted: deleted)
                return nil
            }
            deleted.append(row)
        }
        return merged
    }

    private func restoreEvents(kept: Activity, eventID: String, deleted: [Activity]) {
        if let calendarID = kept.calendarID {
            let back = CalendarEventDraft(calendarID: calendarID, title: kept.text, start: kept.start, end: kept.end)
            if case let .saved(id) = calendarWriter.update(eventID: eventID, draft: back), !id.isEmpty, id != kept.eventID {
                replaceStoredActivity(kept.id) { var a = $0; a.eventID = id; return a }
            }
        }
        for row in deleted {
            guard let calendarID = row.calendarID else { continue }
            let draft = CalendarEventDraft(calendarID: calendarID, title: row.text, start: row.start, end: row.end)
            guard case let .saved(id) = calendarWriter.save(draft), !id.isEmpty else { continue }
            replaceStoredActivity(row.id) { var a = $0; a.eventID = id; return a }
        }
    }
}
