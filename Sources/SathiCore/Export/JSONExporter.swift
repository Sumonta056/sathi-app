import Foundation

package enum JSONExporter {
    package static func backup(
        prefs: Prefs,
        live: LiveState,
        events: [HistoryEvent],
        activities: [Activity] = [],
        exportedAt: Date
    ) -> Data {
        let value = Backup(
            schemaVersion: Limits.schemaVersion,
            exportedAt: exportedAt,
            prefs: prefs,
            live: live,
            events: events,
            activities: activities
        )
        return (try? JSONFiles.encoder().encode(value)) ?? Data()
    }
}

private struct Backup: Encodable {
    var schemaVersion: Int
    var exportedAt: Date
    var prefs: Prefs
    var live: LiveState
    var events: [HistoryEvent]
    var activities: [Activity]
}
