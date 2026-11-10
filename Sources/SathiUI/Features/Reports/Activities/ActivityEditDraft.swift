import Foundation
import SathiCore

struct ActivityEditDraft: Equatable {
    var text: String
    var category: String?
    var startMinutes: Int
    var endMinutes: Int
    private let originalStart: Date
    private let originalEnd: Date
    private let originalStartMinutes: Int
    private let originalEndMinutes: Int

    init(text: String = "", category: String? = nil, start: Date, end: Date, calendar: Calendar) {
        self.text = text
        self.category = category
        originalStart = start
        originalEnd = end
        originalStartMinutes = Self.minutes(start, calendar: calendar)
        originalEndMinutes = Self.minutes(end, calendar: calendar)
        startMinutes = originalStartMinutes
        endMinutes = originalEndMinutes
    }

    init(_ activity: Activity, calendar: Calendar) {
        self.init(text: activity.text, category: activity.category, start: activity.start, end: activity.end, calendar: calendar)
    }

    func edit(dayStart: Date, calendar: Calendar) -> ActivityEdit {
        let start = startMinutes == originalStartMinutes
            ? originalStart : Self.date(startMinutes, dayStart: dayStart, calendar: calendar)
        var end = endMinutes == originalEndMinutes
            ? originalEnd : Self.date(endMinutes, dayStart: dayStart, calendar: calendar)
        if endMinutes != originalEndMinutes, endMinutes == 0, end <= start {
            end = Self.date(Limits.minutesPerDay, dayStart: dayStart, calendar: calendar)
        }
        return ActivityEdit(text: text, category: category, start: start, end: end)
    }

    static func minutes(_ date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * Limits.minutesPerHour + (c.minute ?? 0)
    }

    static func date(_ minutes: Int, dayStart: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: dayStart) ?? dayStart
    }

    static func message(_ result: ActivityEditResult) -> String? {
        switch result {
        case .emptyText: return Copywriter.trackerEditEmpty
        case .tooShort: return Copywriter.trackerEditTooShort
        case .overlap: return Copywriter.trackerEditOverlap
        case .saved, .notFound: return nil
        }
    }
}
