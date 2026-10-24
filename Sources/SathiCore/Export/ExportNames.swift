import Foundation

package enum ExportNames {
    package static func fileName(_ format: ExportFormat, on date: Date, calendar: Calendar) -> String {
        let c = Calendar.gregorian(in: calendar.timeZone).dateComponents([.year, .month, .day], from: date)
        let stamp = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        return prefix(format) + stamp + "." + format.rawValue
    }

    private static func prefix(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return StorageKeys.exportHistoryPrefix
        case .json: return StorageKeys.exportBackupPrefix
        }
    }
}
