import Foundation

package enum HistoryRangeExporter {
    package static func fileName(_ range: StatsRange, calendar: Calendar) -> String {
        ExportNames.rangeFileName(prefix: StorageKeys.exportHistoryRangePrefix, range, calendar: calendar)
    }
}
