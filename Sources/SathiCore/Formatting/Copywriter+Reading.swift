import Foundation

extension Copywriter {
    package static func comesBack(_ id: HabitID, at date: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = calendar.timeZone
        return "\(id.buddy) comes back at " + date.formatted(style)
    }

    package static func readingInviteHint(minutes: Int) -> String {
        "\(minutes) calm minutes with your book."
    }

    package static func readingDoneTitle(minutes: Int) -> String {
        "Lovely, \(minutes) \(minutes == 1 ? "minute" : "minutes") read"
    }

    package static func readingDoneHint(streak: Int) -> String {
        streak >= 2 ? "That is \(streak) days in a row." : "A good start."
    }
}
