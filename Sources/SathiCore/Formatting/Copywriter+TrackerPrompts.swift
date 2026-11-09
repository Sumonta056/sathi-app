import Foundation

extension Copywriter {
    package static let trackerWhatAreYouDoing = "What are you doing?"
    package static let trackerWhatAreYouDoingNow = "What are you doing now?"
    package static let trackerFieldPlaceholder = "Type, or pick a recent one"
    package static let trackerStarted = "Started"
    package static let trackerFor = "For"
    package static let trackerAddToCalendar = "Add to calendar"
    package static let trackerQuietSwitch = "No popups until it ends"
    package static let trackerPickALength = "pick a length"
    package static let trackerCategory = "Category"
    package static let trackerAskMe = "Ask me"
    package static let trackerStart = "Start"
    package static let trackerSkip = "Skip"
    package static let trackerCalendarNote = "Birthdays, Holidays, and subscribed calendars are not shown."
    package static let trackerKeysOptions = "⇥ options"
    package static let trackerKeysStart = "⏎ start"
    package static let trackerKeysSkip = "esc skip"
    package static let trackerOrAskIn = "or ask in"
    package static let trackerDone = "Done"
    package static let trackerStillOnIt = "Still on it"
    package static let trackerDonePick = "Done · pick when you switched"
    package static let trackerWelcomeBack = "Welcome back. What now?"
    package static let trackerSomethingNew = "Something new"
    package static let trackerIWasHere = "I was here"
    package static let trackerWhereWereYou = "Where were you?"
    package static let trackerWhileAway = "WHILE YOU WERE AWAY"
    package static let trackerLogged = "✓ logged"
    package static let trackerNotAttending = "Not attending"
    package static let trackerUndo = "Undo"
    package static let trackerYesLogIt = "Yes, log it"
    package static let trackerNo = "No"
    package static let trackerSwitch = "Switch"

    package static func trackerWhatNowEyebrow(_ time: Date, calendar: Calendar) -> String {
        "WHAT NOW? · " + trackerClock(time, calendar: calendar)
    }

    package static func trackerDoneEyebrow(_ text: String, _ time: Date, calendar: Calendar) -> String {
        "DONE WITH " + text.uppercased() + " · " + trackerClock(time, calendar: calendar)
    }

    package static func trackerEndsAt(_ text: String, _ time: Date, isNow: Bool, calendar: Calendar) -> String {
        text + " ends at " + trackerClock(time, calendar: calendar) + (isNow ? " (now)." : ".")
    }

    package static func trackerQuietUntil(_ time: Date, calendar: Calendar) -> String {
        "quiet until " + trackerClock(time, calendar: calendar)
    }

    package static func trackerContinue(_ text: String) -> String { "Continue " + text }

    package static func trackerStillOnEyebrow(_ time: Date, late: Bool, calendar: Calendar) -> String {
        "STILL ON IT? · " + (late ? "ASKED " : "") + trackerClock(time, calendar: calendar)
    }

    package static func trackerStillSub(category: String?, since: Date, length: ActivityLength, calendar: Calendar) -> String {
        let parts = [category, "since " + trackerClock(since, calendar: calendar), trackerLengthLabel(length)]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    package static func trackerYesMore(_ minutes: Int) -> String { "Yes, \(minutes) min more" }

    package static func trackerWaited(_ minutes: Int) -> String { "This question waited \(minutes) min." }

    package static func trackerAwayEyebrow(_ start: Date, _ end: Date, calendar: Calendar) -> String {
        let minutes = trackerDuration(end.timeIntervalSince(start)).uppercased()
        return "AWAY · " + trackerSpan(start, end, calendar: calendar) + " · " + minutes
    }

    package static func trackerBackTo(_ text: String) -> String { "Back to " + text }

    package static func trackerFromCalendar(_ time: Date, calendar: Calendar) -> String {
        "FROM YOUR CALENDAR · " + trackerClock(time, calendar: calendar)
    }

    package static func trackerEventLogged(_ e: CalendarEventInfo, calendarTitle: String, calendar: Calendar) -> String {
        "Logged from " + trackerClock(e.start, calendar: calendar) + " · until " + trackerClock(e.end, calendar: calendar)
            + " · " + calendarTitle
    }

    package static func trackerEventSpan(_ e: CalendarEventInfo, calendarTitle: String, calendar: Calendar) -> String {
        trackerSpan(e.start, e.end, calendar: calendar) + " · " + calendarTitle
    }

    package static func trackerEventEnded(_ text: String, at time: Date, calendar: Calendar) -> String {
        text + " ended at " + trackerClock(time, calendar: calendar) + ". This note closes in 1 min."
    }

    package static func trackerEventAsk(_ title: String) -> String { title + " started. Log it?" }

    package static func trackerAlsoNow(_ title: String) -> String { "Also now: " + title }
}
