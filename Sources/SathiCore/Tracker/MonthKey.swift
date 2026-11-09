import Foundation

package struct MonthKey: Hashable, Comparable, Codable, Sendable {
    package let year: Int
    package let month: Int

    package init?(year: Int, month: Int) {
        guard (1 ... Limits.monthsPerYear).contains(month), year > 0 else { return nil }
        self.year = year
        self.month = month
    }

    package init(_ date: Date, calendar: Calendar) {
        let c = Calendar.gregorian(in: calendar.timeZone).dateComponents([.year, .month], from: date)
        year = c.year ?? 1
        month = c.month ?? 1
    }

    package init?(raw: String) {
        guard let m = raw.wholeMatch(of: #/([0-9]{4})-([0-9]{2})/#), let y = Int(m.1), let mo = Int(m.2) else { return nil }
        self.init(year: y, month: mo)
    }

    package var raw: String { String(format: "%04d-%02d", year, month) }

    package var next: MonthKey {
        month == Limits.monthsPerYear ? MonthKey(year: year + 1, month: 1) ?? self : MonthKey(year: year, month: month + 1) ?? self
    }

    package var previous: MonthKey {
        month == 1 ? MonthKey(year: year - 1, month: Limits.monthsPerYear) ?? self : MonthKey(year: year, month: month - 1) ?? self
    }

    package func start(in calendar: Calendar) -> Date {
        let g = Calendar.gregorian(in: calendar.timeZone)
        return g.date(from: DateComponents(year: year, month: month, day: 1)) ?? .distantPast
    }

    package func end(in calendar: Calendar) -> Date { next.start(in: calendar) }

    package static func < (a: MonthKey, b: MonthKey) -> Bool { (a.year, a.month) < (b.year, b.month) }

    package init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let text = try c.decode(String.self)
        guard let key = MonthKey(raw: text) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not a month key: \(text)")
        }
        self = key
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }
}
