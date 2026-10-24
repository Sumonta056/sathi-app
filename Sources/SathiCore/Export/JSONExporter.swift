import Foundation

package enum JSONExporter {
    package static func backup(prefs: Prefs, live: LiveState, events: [HistoryEvent], exportedAt: Date) -> Data {
        let value = Backup(schemaVersion: Limits.schemaVersion, exportedAt: exportedAt, prefs: prefs, live: live, events: events)
        return (try? JSONFiles.encoder().encode(value)) ?? Data()
    }
}

private struct Backup: Encodable {
    var schemaVersion: Int
    var exportedAt: Date
    var prefs: Prefs
    var live: LiveState
    var events: [HistoryEvent]
}
