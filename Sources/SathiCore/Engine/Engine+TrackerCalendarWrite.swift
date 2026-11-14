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
    ) -> (activity: Activity, outcome: CalendarEditOutcome) {
        guard old.kind == .work, old.sourceEventID == nil else { return (calendarActivityEdited(from: old, to: new), .ok) }
        let oldEvent = old.eventID.flatMap { $0.isEmpty ? nil : $0 }
        switch choice {
        case .keep:
            return (calendarActivityEdited(from: old, to: new), .ok)
        case .none:
            if let oldEvent, calendarWriter.delete(eventID: oldEvent) != .deleted { return (calendarActivityEdited(from: old, to: new), .unchanged) }
            var a = new
            a.calendarID = nil
            a.eventID = nil
            return (a, .ok)
        case let .calendar(id) where id == old.calendarID && oldEvent != nil:
            return (calendarActivityEdited(from: old, to: new), .ok)
        case let .calendar(id):
            return movedToCalendar(id, from: old, to: new, oldEvent: oldEvent)
        }
    }

    private func movedToCalendar(
        _ id: String, from old: Activity, to new: Activity, oldEvent: String?
    ) -> (activity: Activity, outcome: CalendarEditOutcome) {
        var a = new
        a.calendarID = id
        a.eventID = nil
        a = savingToCalendar(a)
        guard let written = a.eventID else {
            return (oldEvent == nil ? a : calendarActivityEdited(from: old, to: new), .unchanged)
        }
        guard let oldEvent else { return (a, .ok) }
        if calendarWriter.delete(eventID: oldEvent) == .deleted { return (a, .ok) }
        guard calendarWriter.delete(eventID: written) == .deleted else { return (a, .oldEventKept) }
        return (calendarActivityEdited(from: old, to: new), .unchanged)
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
        return calendarWriter.delete(eventID: eventID) != .failed
    }
}
