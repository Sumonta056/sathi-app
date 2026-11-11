import Foundation

package enum ExportNames {
    package static func fileName(_ format: ExportFormat, on date: Date, calendar: Calendar) -> String {
        let c = Calendar.gregorian(in: calendar.timeZone).dateComponents([.year, .month, .day], from: date)
        let stamp = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        return prefix(format) + stamp + "." + format.rawValue
    }

    package static func rangeFileName(prefix: String, _ range: StatsRange, calendar: Calendar) -> String {
        let last = range.days.last?.start ?? range.interval.start
        let first = DayKey(range.interval.start, calendar: calendar).raw
        return prefix + first + "-" + DayKey(last, calendar: calendar).raw + "." + ExportFormat.csv.rawValue
    }

    private static func prefix(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return StorageKeys.exportHistoryPrefix
        case .json: return StorageKeys.exportBackupPrefix
        case .pdf: return StorageKeys.exportSummaryPrefix
        }
    }
}
