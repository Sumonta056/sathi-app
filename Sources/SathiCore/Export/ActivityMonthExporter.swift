import Foundation

package enum ActivityMonthExporter {
    static let header = "start,end,minutes,kind,category,text,place"
    private static let formulaStarts: Set<Character> = ["=", "+", "-", "@", "\t", "\r", "\r\n"]

    package static func csv(_ month: ActivityMonth, timeZone: TimeZone) -> String {
        let formatter = timestampFormatter(timeZone)
        let rows = sorted(month).map { item in
            [
                formatter.string(from: item.start),
                formatter.string(from: item.end),
                String(Int(item.length / Timing.minute)),
                item.kind.rawValue,
                field(item.category ?? ""),
                field(item.text),
                item.awayPlace?.rawValue ?? ""
            ].joined(separator: ",")
        }
        return ([header] + rows).map { $0 + "\n" }.joined()
    }

    package static func json(_ month: ActivityMonth, exportedAt: Date) -> Data {
        let value = Export(
            schemaVersion: Limits.schemaVersion,
            month: month.key,
            exportedAt: exportedAt,
            items: sorted(month)
        )
        return (try? JSONFiles.encoder().encode(value)) ?? Data()
    }

    package static func fileName(_ month: MonthKey, format: ExportFormat) -> String {
        StorageKeys.exportActivitiesPrefix + month.raw + "." + format.rawValue
    }

    private static func sorted(_ month: ActivityMonth) -> [Activity] {
        month.items.sorted { $0.start < $1.start }
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

private struct Export: Encodable {
    var schemaVersion: Int
    var month: MonthKey
    var exportedAt: Date
    var items: [Activity]
}
