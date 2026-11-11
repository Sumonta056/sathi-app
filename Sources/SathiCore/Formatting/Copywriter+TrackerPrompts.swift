import Foundation

extension Copywriter {
    package static let trackerWhatAreYouDoingNow = "What are you doing now?"
    package static let trackerFieldPlaceholder = "Type, or pick a recent one"
    package static let trackerFor = "For"
    package static let trackerQuietSwitch = "No popups until it ends"
    package static let trackerCategory = "Category"
    package static let trackerAskMe = "Ask me"
    package static let trackerStart = "Start"
    package static let trackerSkip = "Skip"
    package static let trackerCheck = "✓"
    package static let trackerNoteCloses = "Logged now · this note closes in \(Int(Timing.eventNoteShow / Timing.minute)) min"
    package static let trackerStillOnIt = "Still on it"
    package static let trackerWhatNow = "What now?"
    package static let trackerAddPlace = "Add"
    package static let trackerNewPlace = "New place"
    package static let trackerIWasHere = "I was here"
    package static let trackerWhereWereYou = "Where were you?"
    package static let trackerLogged = "✓ logged"
    package static let trackerNotAttending = "Not attending"
    package static let trackerUndo = "Undo"
    package static let trackerSwitch = "Switch"

    package static func trackerContinue(_ text: String) -> String { "Continue " + text }

    package static func trackerWaited(_ minutes: Int) -> String { "This question waited \(minutes) min." }

    package static func trackerFromCalendar(_ time: Date, calendar: Calendar) -> String {
        "FROM YOUR CALENDAR · " + trackerClock(time, calendar: calendar)
    }

    package static func trackerEventSpan(_ e: CalendarEventInfo, calendarTitle: String, calendar: Calendar) -> String {
        trackerSpan(e.start, e.end, calendar: calendar) + " · " + calendarTitle
    }

    package static func trackerEventEnded(_ text: String, at time: Date, calendar: Calendar) -> String {
        text + " ended at " + trackerClock(time, calendar: calendar) + ". This note closes in \(Int(Timing.eventNoteShow / Timing.minute)) min."
    }

    package static func trackerAlsoNow(_ title: String) -> String { "Also now: " + title }
}
