import Foundation

package enum ActivityMonthExporter {
    package static func csv(_ month: ActivityMonth, timeZone: TimeZone) -> String {
        ActivityRangeExporter.csv(month.items, timeZone: timeZone)
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
}

private struct Export: Encodable {
    var schemaVersion: Int
    var month: MonthKey
    var exportedAt: Date
    var items: [Activity]
}
