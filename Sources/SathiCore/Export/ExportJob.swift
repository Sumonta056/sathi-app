import Foundation

package struct ExportJob: Sendable {
    package var history: HistoryStore
    package var prefs: Prefs
    package var live: LiveState
    package var exportedAt: Date
    package var timeZone: TimeZone

    package init(history: HistoryStore, prefs: Prefs, live: LiveState, exportedAt: Date, timeZone: TimeZone) {
        self.history = history
        self.prefs = prefs
        self.live = live
        self.exportedAt = exportedAt
        self.timeZone = timeZone
    }

    package nonisolated func write(_ format: ExportFormat, to url: URL) -> ExportOutcome {
        let data: Data
        switch format {
        case .csv:
            data = Data(CSVExporter.csv(history.allEvents(), timeZone: timeZone).utf8)
        case .json:
            data = JSONExporter.backup(prefs: prefs, live: live, events: history.allEvents(), exportedAt: exportedAt)
        case .pdf:
            return .failed
        }
        return Self.write(data, to: url)
    }

    static func write(_ data: Data, to url: URL) -> ExportOutcome {
        do {
            try data.write(to: url, options: .atomic)
            return .saved(url)
        } catch {
            return .failed
        }
    }
}
