import Foundation

extension Engine {
    package func readableCalendarChoices() -> [CalendarChoice] { [] }

    @discardableResult
    package func saveActivityToCalendar(_ id: ActivityID) -> Bool { false }

    package func trackerNoteState() -> TrackerNoteState? { nil }
    package func undoEventNote() {}
    package func notAttendingEvent(_ eventID: String) {}
    package func setEventCategory(_ category: String) {}
    package func answerEventAsk(_ yes: Bool) {}
    package func switchToOverlappingEvent() {}

    var trackerEventDeadlines: [Date] { [] }

    func tickTrackerEvents() {}
    func unloggedRunningEvent() -> CalendarEventInfo? { nil }
    func savingToCalendar(_ activity: Activity) -> Activity { activity }
    func calendarActivityEdited(from old: Activity, to new: Activity) -> Activity { new }
    func calendarActivityDeleted(_ activity: Activity) {}
    func logEventsWhileAway(from start: Date, to end: Date) -> [Activity] { [] }
}
