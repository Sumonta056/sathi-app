import Foundation

package struct DayKey: Hashable, Comparable, Codable, Sendable {
    package let raw: String

    package init?(raw: String) {
        guard let parts = Self.parts(raw) else { return nil }
        let utc = Calendar.gregorian(in: .gmt)
        guard parts.isValidDate(in: utc) else { return nil }
        self.raw = raw
    }

    package init(_ date: Date, calendar: Calendar) {
        let c = Calendar.gregorian(in: calendar.timeZone).dateComponents([.year, .month, .day], from: date)
        raw = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    package func start(in calendar: Calendar) -> Date {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let c = Self.parts(raw) ?? DateComponents()
        return g.startOfDay(for: g.date(from: c) ?? .distantPast)
    }

    package static func < (a: DayKey, b: DayKey) -> Bool { a.raw < b.raw }

    package init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let text = try c.decode(String.self)
        guard let key = DayKey(raw: text) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Not a day key: \(text)")
        }
        self = key
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }

    private static func parts(_ raw: String) -> DateComponents? {
        guard let m = raw.wholeMatch(of: #/([0-9]{4})-([0-9]{2})-([0-9]{2})/#),
              let y = Int(m.1), let mo = Int(m.2), let d = Int(m.3) else { return nil }
        return DateComponents(year: y, month: mo, day: d)
    }
}
