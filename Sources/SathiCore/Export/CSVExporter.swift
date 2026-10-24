import Foundation

package enum CSVExporter {
    static let header = "timestamp,habit,kind,amount"

    package static func csv(_ events: [HistoryEvent], timeZone: TimeZone) -> String {
        let formatter = timestampFormatter(timeZone)
        let rows = events.sorted { $0.date < $1.date }.map { e in
            [formatter.string(from: e.date), e.habit.rawValue, e.kind.rawValue, amount(e.amount)].joined(separator: ",")
        }
        return ([header] + rows).map { $0 + "\n" }.joined()
    }

    static func amount(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(value)
    }

    private static func timestampFormatter(_ timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = timeZone
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxxxx"
        return f
    }
}
