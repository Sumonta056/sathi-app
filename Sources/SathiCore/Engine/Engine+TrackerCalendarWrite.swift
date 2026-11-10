import Foundation

extension Engine {
    @discardableResult
    package func saveActivityToCalendar(_ id: ActivityID) -> Bool {
        guard let old = storedActivity(id), old.calendarID != nil, old.eventID == nil else { return false }
        let new = savingToCalendar(old)
        guard new.eventID != nil else { return false }
        removeStoredActivity(id)
        storeActivity(new)
        return true
    }

    func savingToCalendar(_ activity: Activity) -> Activity {
        guard activity.kind == .work, activity.sourceEventID == nil, activity.eventID == nil,
              let calendarID = activity.calendarID else { return activity }
        var a = activity
        let draft = CalendarEventDraft(calendarID: calendarID, title: a.text, start: a.start, end: a.end)
        if case let .saved(id) = calendarWriter.save(draft), !id.isEmpty { a.eventID = id }
        return a
    }

    func calendarActivityEdited(from old: Activity, to new: Activity) -> Activity {
        guard let eventID = old.eventID, !eventID.isEmpty, let calendarID = new.calendarID ?? old.calendarID else { return new }
        var a = new
        a.eventID = eventID
        let draft = CalendarEventDraft(calendarID: calendarID, title: a.text, start: a.start, end: a.end)
        if case let .saved(id) = calendarWriter.update(eventID: eventID, draft: draft), !id.isEmpty { a.eventID = id }
        return a
    }

    func calendarActivityDeleted(_ activity: Activity) {
        guard let eventID = activity.eventID, !eventID.isEmpty else { return }
        calendarWriter.delete(eventID: eventID)
    }
}
