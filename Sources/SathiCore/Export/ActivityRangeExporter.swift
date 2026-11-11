import Foundation

package enum ActivityRangeExporter {
    static let header = "start,end,minutes,kind,category,text,place"
    private static let formulaStarts: Set<Character> = ["=", "+", "-", "@", "\t", "\r", "\r\n"]

    package static func csv(_ items: [Activity], timeZone: TimeZone) -> String {
        let formatter = timestampFormatter(timeZone)
        let rows = items.sorted { $0.start < $1.start }.map { item in
            [
                formatter.string(from: item.start),
                formatter.string(from: item.end),
                String(Int(item.length / Timing.minute)),
                item.kind.rawValue,
                field(item.category ?? ""),
                field(item.text),
                field(item.awayPlaceName ?? item.awayPlace?.rawValue ?? "")
            ].joined(separator: ",")
        }
        return ([header] + rows).map { $0 + "\n" }.joined()
    }

    package static func fileName(_ range: StatsRange, calendar: Calendar) -> String {
        ExportNames.rangeFileName(prefix: StorageKeys.exportActivitiesRangePrefix, range, calendar: calendar)
    }

    private static func field(_ text: String) -> String {
        let flat = text.replacingOccurrences(of: "\r", with: " ").replacingOccurrences(of: "\n", with: " ")
        let risky = [text.first, flat.first].contains { $0.map(formulaStarts.contains) == true }
        let safe = risky ? "'" + flat : flat
        guard safe.contains(",") || safe.contains("\"") else { return safe }
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
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
