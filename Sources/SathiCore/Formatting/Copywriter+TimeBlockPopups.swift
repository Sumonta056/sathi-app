import Foundation

extension Copywriter {
    package static let blockEndAndSave = "End and save"
    package static let blockDoneEyebrow = "TIME BLOCK · DONE"
    package static let blockDone = "Done"
    package static let blockKeepGoing = "Keep going"
    package static let blockYourCalendar = "your calendar"
    package static let blockGoneEyebrow = "TIME BLOCK · NOT SAVED YET"
    package static let blockAllowCalendarAccess = "Allow calendar access"
    package static let blockNoAccessHeadline = "Sathi can’t reach your calendars"
    package static let blockNoWritableCalendar = "No calendar you can save to. Add one in the Calendar app."
    package static let blockExtendLabel = "+\(Int(Timing.blockExtend / Timing.minute)) min"
    package static let blockCheckInEyebrow = "TIME BLOCK · \(checkInHours) HOURS"

    private static var checkInHours: Int { Int(Timing.blockCheckIn / Timing.hour) }

    package static func blockDoneSummary(minutes: Int, title: String) -> String {
        blockLength(minutes) + " on " + title
    }

    package static func blockSavedTo(_ calendarTitle: String, start: Date, end: Date, calendar: Calendar) -> String {
        "Saved to " + calendarTitle + " · " + quickClock(start, calendar: calendar) + " – " + quickClock(end, calendar: calendar)
    }

    package static func blockStartedAt(_ start: Date, calendar: Calendar) -> String {
        "Started at " + quickClock(start, calendar: calendar) + ". Sathi asks again in \(checkInHours) hours."
    }

    package static func blockNoAccessDetail(minutes: Int, title: String) -> String {
        "Allow calendar access in System Settings to save " + blockLength(minutes) + " on " + title + "."
    }

    package static func blockChooseCalendar(minutes: Int, title: String) -> String {
        "Choose one to save " + blockLength(minutes) + " on " + title + "."
    }

    package static func blockWidgetHint(end: Date?, start: Date, calendarTitle: String, calendar: Calendar) -> String {
        let time = end.map { "ends " + quickClock($0, calendar: calendar) } ?? "since " + quickClock(start, calendar: calendar)
        return time + " · " + calendarTitle
    }
}
