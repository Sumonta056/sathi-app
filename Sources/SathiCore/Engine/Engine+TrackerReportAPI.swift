import Foundation

extension Engine {
    package var trackerPromptByUser: Bool { trackerRuntime.promptByUser }
    package var trackerPromptTakesKeyboard: Bool { trackerPrompt != nil && trackerPromptByUser }

    package func activityDay(_ day: DayKey) -> ActivityDay {
        let start = day.start(in: calendar)
        var running: Activity?
        if let r = data.live.tracker.running, calendar.isDate(r.start, inSameDayAs: start) {
            running = r.activity(until: max(r.start, min(clock.now, calendar.nextDay(after: r.start))))
        }
        return ActivityDay(day: day, hours: trackerHours.hours(on: start), activities: storedActivities(on: start), running: running)
    }

    package func activityDays(in month: MonthKey) -> [ActivityDay] {
        daysWithActivities(in: month).sorted().map(activityDay)
    }

    package func daysWithActivities(in month: MonthKey) -> Set<DayKey> {
        var days = Set(activityStore.month(month).items.map { DayKey($0.start, calendar: calendar) })
        if let r = data.live.tracker.running, MonthKey(r.start, calendar: calendar) == month {
            days.insert(DayKey(r.start, calendar: calendar))
        }
        return days
    }

    @discardableResult
    package func editActivity(_ id: ActivityID, _ edit: ActivityEdit) -> ActivityEditResult {
        clearMergeUndo()
        guard let old = storedActivity(id), old.kind != .timeBlock else { return .notFound }
        if let kind = edit.kind, kind != old.kind { return switchedKind(old, to: kind, edit: edit.wholeSeconds) }
        let edit = old.kind == .away ? awayEdit(edit.wholeSeconds) : edit.wholeSeconds
        if let problem = ActivityEditCheck.problem(edit, others: busySpans(near: edit, except: id), calendar: calendar) { return problem }
        if edit.end > clock.now { return .inFuture }
        var new = old
        var outcome = CalendarEditOutcome.ok
        new.text = ActivityText.clean(edit.text) ?? old.text
        new.start = edit.start
        new.end = edit.end
        if old.kind == .away {
            new.awayPlace = edit.awayPlace
            new.awayPlaceName = edit.awayPlaceName
        } else {
            new.category = edit.category
            let moved = calendarActivityEdited(from: old, to: new, choice: edit.calendar)
            new = moved.activity
            outcome = moved.outcome
        }
        removeStoredActivity(id)
        storeActivity(new)
        switch outcome {
        case .ok: return .saved(id)
        case .unchanged: return .calendarUnchanged(id)
        case .oldEventKept: return .calendarFailed(id)
        }
    }

    @discardableResult
    package func addPastActivity(_ edit: ActivityEdit) -> ActivityEditResult {
        clearMergeUndo()
        let edit = edit.wholeSeconds
        if let problem = ActivityEditCheck.problem(edit, others: busySpans(near: edit, except: nil), calendar: calendar) { return problem }
        if edit.end > clock.now { return .inFuture }
        var item = Activity(text: ActivityText.clean(edit.text) ?? edit.text, category: edit.category, start: edit.start, end: edit.end)
        if case let .calendar(id) = edit.calendar {
            item.calendarID = id
            item = savingToCalendar(item)
        }
        storeActivity(item)
        return .saved(item.id)
    }

    private func switchedKind(_ old: Activity, to kind: ActivityKind, edit: ActivityEdit) -> ActivityEditResult {
        let canSwitch = (old.kind == .work && old.sourceEventID == nil) || old.kind == .away
        guard canSwitch, kind == .work || kind == .away else { return .notFound }
        if rowsInAwayUndo().contains(old.id) { return .awayUndo }
        let edit = kind == .away ? awayEdit(edit) : edit
        if let problem = ActivityEditCheck.problem(edit, others: busySpans(near: edit, except: old.id), calendar: calendar) { return problem }
        if edit.end > clock.now { return .inFuture }
        if kind == .away, let event = old.eventID, !event.isEmpty, calendarWriter.delete(eventID: event) != .deleted {
            return .calendarUnchanged(old.id)
        }
        var new = old
        new.kind = kind
        new.text = ActivityText.clean(edit.text) ?? old.text
        new.category = edit.category
        new.start = edit.start
        new.end = edit.end
        new.awayPlace = kind == .away ? edit.awayPlace : nil
        new.awayPlaceName = kind == .away ? edit.awayPlaceName : nil
        new.calendarID = nil
        new.eventID = nil
        if kind == .work, case let .calendar(id) = edit.calendar {
            new.calendarID = id
            new = savingToCalendar(new)
        }
        removeStoredActivity(old.id)
        storeActivity(new)
        return new.calendarID != nil && new.eventID == nil ? .calendarUnchanged(old.id) : .saved(old.id)
    }

    private func awayEdit(_ edit: ActivityEdit) -> ActivityEdit {
        ActivityEdit(
            text: Copywriter.trackerAwayText(edit.awayPlace, name: edit.awayPlaceName), category: nil,
            start: edit.start, end: edit.end, awayPlace: edit.awayPlace, awayPlaceName: edit.awayPlaceName
        )
    }

    @discardableResult
    package func deleteActivity(_ id: ActivityID) -> Bool {
        clearMergeUndo()
        guard let old = storedActivity(id), calendarActivityDeleted(old) else { return false }
        removeStoredActivity(id)
        return true
    }

    private func busySpans(near edit: ActivityEdit, except id: ActivityID?) -> [DateInterval] {
        var items = storedActivities(on: edit.start)
        if !calendar.isDate(edit.start, inSameDayAs: edit.end) { items += storedActivities(on: edit.end) }
        var spans = items.filter { $0.id != id }.map(\.interval)
        if let r = data.live.tracker.running {
            spans.append(DateInterval(start: r.start, end: max(r.start, clock.now)))
        }
        return spans
    }
}
