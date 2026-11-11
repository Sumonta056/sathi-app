import Foundation

extension Engine {
    func savingToCalendar(_ activity: Activity) -> Activity {
        guard activity.kind == .work, activity.sourceEventID == nil, activity.eventID == nil,
              let calendarID = activity.calendarID else { return activity }
        var a = activity
        let draft = CalendarEventDraft(calendarID: calendarID, title: a.text, start: a.start, end: a.end)
        if case let .saved(id) = calendarWriter.save(draft), !id.isEmpty { a.eventID = id }
        return a
    }

    func calendarActivityEdited(
        from old: Activity, to new: Activity, choice: ActivityCalendarChoice
    ) -> (activity: Activity, calendarOK: Bool) {
        guard old.kind == .work, old.sourceEventID == nil else { return (calendarActivityEdited(from: old, to: new), true) }
        let oldEvent = old.eventID.flatMap { $0.isEmpty ? nil : $0 }
        switch choice {
        case .keep:
            return (calendarActivityEdited(from: old, to: new), true)
        case .none:
            if let oldEvent, !calendarWriter.delete(eventID: oldEvent) { return (calendarActivityEdited(from: old, to: new), false) }
            var a = new
            a.calendarID = nil
            a.eventID = nil
            return (a, true)
        case let .calendar(id) where id == old.calendarID && oldEvent != nil:
            return (calendarActivityEdited(from: old, to: new), true)
        case let .calendar(id):
            return movedToCalendar(id, from: old, to: new, oldEvent: oldEvent)
        }
    }

    private func movedToCalendar(
        _ id: String, from old: Activity, to new: Activity, oldEvent: String?
    ) -> (activity: Activity, calendarOK: Bool) {
        var a = new
        a.calendarID = id
        a.eventID = nil
        a = savingToCalendar(a)
        guard let oldEvent else { return (a, true) }
        guard let written = a.eventID else { return (calendarActivityEdited(from: old, to: new), true) }
        if calendarWriter.delete(eventID: oldEvent) { return (a, true) }
        guard calendarWriter.delete(eventID: written) else { return (a, false) }
        return (calendarActivityEdited(from: old, to: new), true)
    }

    func calendarActivityEdited(from old: Activity, to new: Activity) -> Activity {
        guard let eventID = old.eventID, !eventID.isEmpty, let calendarID = new.calendarID ?? old.calendarID else { return new }
        var a = new
        a.eventID = eventID
        let draft = CalendarEventDraft(calendarID: calendarID, title: a.text, start: a.start, end: a.end)
        if case let .saved(id) = calendarWriter.update(eventID: eventID, draft: draft), !id.isEmpty { a.eventID = id }
        return a
    }

    @discardableResult
    func calendarActivityDeleted(_ activity: Activity) -> Bool {
        guard let eventID = activity.eventID, !eventID.isEmpty else { return true }
        return calendarWriter.delete(eventID: eventID)
    }
}
