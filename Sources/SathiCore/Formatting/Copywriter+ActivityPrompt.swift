import Foundation

extension Copywriter {
    package static let activityPromptSwitchTitle = "Switch to something new?"
    package static let activityPromptAskTag = "TIME TO CHECK"
    package static let activityPromptShortcutTag = "YOU ASKED"
    package static let activityPromptEndedTag = "ACTIVITY ENDED"
    package static let activityPromptStillTag = "STILL ON IT?"
    package static let activityPromptBackTag = "WELCOME BACK"
    package static let activityPromptEventTag = "CALENDAR EVENT"
    package static let activityPromptNothingRuns = "Nothing is running."
    package static let activityPromptNow = "now"
    package static let activityPromptLogIt = "Log it"
    package static let activityPromptRecentLabel = "RECENT"
    package static let activityPromptTapToFill = "tap to fill"
    package static let activityPromptRecent = activityPromptRecentLabel + " · " + activityPromptTapToFill
    package static let activityPromptQuiet = "Quiet"
    package static let activityPromptAllowCalendar = "Allow calendar access"
    package static let activityPromptField = "Type what you do, or tap a card on the left"
    package static let activityPromptAddPlace = "+ Place"
    package static let activityPromptReallyStarted = "It really started at"
    package static let activityPromptEscSkip = "Esc: Skip"
    package static let activityPromptNoEvent = "Sathi adds no event for this activity."
    package static let activityPromptCalendarNone = "None"

    package static func activityPromptShortcutTag(_ shortcut: KeyShortcut?) -> String {
        shortcut.map { activityPromptShortcutTag + " · " + trackerShortcut($0) } ?? activityPromptShortcutTag
    }

    package static func activityPromptEventTitle(_ title: String) -> String { "Log “" + title + "” now?" }

    package static func activityPromptEnded(_ text: String, at time: Date, calendar: Calendar) -> String {
        text + " ended at " + trackerClock(time, calendar: calendar) + "."
    }

    package static func activityPromptNothingEnded(_ text: String, at time: Date, calendar: Calendar) -> String {
        activityPromptNothingRuns + " " + activityPromptEnded(text, at: time, calendar: calendar)
    }

    package static func activityPromptRunning(_ text: String, minutes: Int, since start: Date, calendar: Calendar) -> String {
        "Now: " + text + " · \(minutes) min since " + trackerClock(start, calendar: calendar) + ". Switch ends it."
    }

    package static func activityPromptSoFar(_ text: String, minutes: Int, category: String?) -> String {
        text + " · \(minutes) min so far" + (category.map { " as " + $0 } ?? "") + "."
    }

    package static func activityPromptUntilNow(_ start: Date, calendar: Calendar) -> String {
        trackerClock(start, calendar: calendar) + " – " + activityPromptNow
    }

    package static func activityPromptAway(_ away: AwaySpan, calendar: Calendar) -> String {
        "AWAY " + trackerSpan(away.start, away.end, calendar: calendar)
    }

    package static func activityPromptStopped(_ text: String, at time: Date, cause: AwayCause, calendar: Calendar) -> String {
        text + " stopped at " + trackerClock(time, calendar: calendar) + " " + activityPromptCause(cause)
    }

    package static func activityPromptAwayFor(minutes: Int) -> String { "You were away \(minutes) min." }

    package static func activityPromptEvent(_ e: CalendarEventInfo, calendarTitle: String, calendar: Calendar) -> String {
        e.title + " is in your " + calendarTitle + " calendar. It ends by itself at " + trackerClock(e.end, calendar: calendar) + "."
    }

    package static func activityPromptEventCalendar(_ calendarTitle: String) -> String {
        "Already in your " + calendarTitle + " calendar, so Sathi adds no copy."
    }

    package static func activityPromptCalendarGoes(_ calendarTitle: String) -> String {
        "One event goes to " + calendarTitle + " when the activity ends."
    }

    package static func activityPromptKey(_ number: Int) -> String { "⌘\(number)" }

    package static func activityPromptRecentDetail(category: String?, length: TimeInterval) -> String {
        (category ?? trackerNoCategory) + " · last " + trackerDuration(length)
    }

    package static func activityPromptShowAll(_ count: Int) -> String { "Show all \(count)" }

    package static func activityPromptStarted(_ time: Date?, calendar: Calendar) -> String {
        "Started: " + (time.map { trackerClock($0, calendar: calendar) } ?? trackerNow) + " · change"
    }

    package static func activityPromptUntil(_ end: Date, calendar: Calendar) -> String {
        "Until " + trackerClock(end, calendar: calendar)
    }

    package static func activityPromptKeep(_ keep: PromptKeep) -> String {
        switch keep {
        case let .continueLast(text): return trackerContinue(text)
        case let .keep(text): return "Keep " + text
        case let .keepGoing(minutes): return "Keep going +\(minutes) min"
        case .stillOnLate: return trackerStillOnIt
        case let .backTo(text): return "Back to " + text
        }
    }

    private static func activityPromptCause(_ cause: AwayCause) -> String {
        switch cause {
        case .asleep: return "when the Mac went to sleep."
        case .locked: return "when the Mac was locked."
        case .idle: return "when the Mac was idle."
        case .onBreak: return "when you took a break."
        }
    }
}
