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

extension Copywriter {
    package static let readingListEmpty = "Add a link and Boi will suggest it at reading time."

    package static let readingLinkPlaceholder = "Paste a link"
    package static let readingTitlePlaceholder = "Title (optional)"
    package static let readingPaste = "Paste"
    package static let readingAdd = "Add"
    package static let readingUpNext = "Up next"
    package static let readingUndo = "Undo"

    package static func readingMoveUp(_ title: String) -> String { "Move \(title) up" }
    package static func readingMoveDown(_ title: String) -> String { "Move \(title) down" }
    package static func readingUndoLabel(_ title: String) -> String { "Undo \(title)" }
    package static func readingRemove(_ title: String) -> String { "Remove \(title)" }

    package static func readingProblem(_ result: ReadingAddResult) -> String? {
        switch result {
        case .added: nil
        case .unsupportedScheme: "Only web links and files."
        case .missingHost: "That does not look like a link."
        case .tooLong: "That link is too long."
        case .duplicate: "That link is already on your list."
        case .full: "Your list is full. Read one first."
        }
    }

    package static func readingReadHeader(count: Int) -> String {
        "Read · \(count)"
    }

    package static func readingReadOn(_ day: DayKey) -> String {
        "Read " + dayFormatter.string(from: day.start(in: dayCalendar))
    }

    private static let dayCalendar = Calendar.gregorian(in: .gmt)

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = dayCalendar
        f.timeZone = .gmt
        f.dateFormat = "MMM d"
        return f
    }()
}
