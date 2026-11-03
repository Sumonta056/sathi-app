import Foundation

extension Copywriter {
    package static let blockCardTitle = "Time block"
    package static let blockStartButton = "Start a time block"
    package static let blockEyebrow = "NEW TIME BLOCK"
    package static let blockPrompt = "What are you working on?"
    package static let blockEndNow = "End now"
    package static let blockUndo = "Undo"
    package static let blockSaveHere = "Save here"
    package static let blockOpenSettings = "Open System Settings"
    package static let blockNoAccess = "Sathi needs calendar access to save your time blocks."
    package static let blockStart = "Start"
    package static let blockOpen = "Open"

    package static func blockChipLabel(_ length: TimeBlockLength) -> String {
        guard let m = length.minutes else { return blockOpen }
        return m % Limits.minutesPerHour == 0 ? "\(m / Limits.minutesPerHour) h" : "\(m)"
    }

    package static func blockStartLabel(end: Date?, calendar: Calendar) -> String {
        guard let end else { return blockStart }
        return blockStart + " · ends at " + quickClock(end, calendar: calendar)
    }

    package static func blockProgress(elapsed: Int, total: Int, end: Date, calendar: Calendar) -> String {
        "\(elapsed) of \(total) min · ends at " + quickClock(end, calendar: calendar)
    }

    package static func blockSince(start: Date, minutes: Int, calendar: Calendar) -> String {
        "Since " + quickClock(start, calendar: calendar) + " · \(minutes) min"
    }

    package static func blockStartedTitle(_ title: String) -> String {
        "Started · " + title
    }

    package static func blockStartedDetail(length: TimeBlockLength, end: Date?, calendarTitle: String, calendar: Calendar) -> String {
        guard let m = length.minutes, let end else { return blockOpen + " · " + calendarTitle }
        return blockLength(m) + " · ends at " + quickClock(end, calendar: calendar) + " · " + calendarTitle
    }

    package static func blockLength(_ minutes: Int) -> String {
        guard minutes >= Limits.minutesPerHour, minutes % Limits.minutesPerHour == 0 else { return "\(minutes) min" }
        return "\(minutes / Limits.minutesPerHour) h"
    }
}
