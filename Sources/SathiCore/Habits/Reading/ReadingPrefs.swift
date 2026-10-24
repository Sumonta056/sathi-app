import Foundation

package struct ReadingPrefs: Codable, Equatable, Sendable {
    package var enabled = true
    package var timeMinutes = 22 * 60
    package var sessionMinutes = 15
    package var strictness: Strictness = .persistent
    package var weekdays: Set<Weekday> = Set(Weekday.allCases)
    package var reminderStyle: ReadingReminderStyle = .corner

    package init() {}

    enum CodingKeys: String, CodingKey {
        case enabled, timeMinutes, sessionMinutes, strictness, weekdays, reminderStyle
    }

    package var sortedWeekdays: [Weekday] {
        Weekday.allCases.filter(weekdays.contains)
    }
}

extension ReadingPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ReadingPrefs()
        enabled = try c.value(.enabled, or: d.enabled)
        timeMinutes = try c.value(.timeMinutes, or: d.timeMinutes)
        sessionMinutes = try c.value(.sessionMinutes, or: d.sessionMinutes)
        strictness = try c.value(.strictness, or: d.strictness)
        weekdays = try c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)
        reminderStyle = try c.known(.reminderStyle, or: d.reminderStyle)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(timeMinutes, forKey: .timeMinutes)
        try c.encode(sessionMinutes, forKey: .sessionMinutes)
        try c.encode(strictness, forKey: .strictness)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(reminderStyle, forKey: .reminderStyle)
    }
}
