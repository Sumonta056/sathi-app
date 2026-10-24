import Foundation
import SathiCore

package final class SpyFileExporter: FileExporter {
    package struct Save: Equatable {
        package var data: Data
        package var suggestedName: String
        package var format: ExportFormat
    }

    package private(set) var saves: [Save] = []
    package var result = true

    package init() {}

    @discardableResult
    package func save(_ data: Data, suggestedName: String, format: ExportFormat) -> Bool {
        saves.append(Save(data: data, suggestedName: suggestedName, format: format))
        return result
    }
}

package struct DecodedBackup: Decodable {
    package var schemaVersion: Int
    package var exportedAt: Date
    package var prefs: Prefs
    package var live: LiveState
    package var events: [HistoryEvent]

    package static func decode(_ data: Data) -> DecodedBackup? {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try? d.decode(DecodedBackup.self, from: data)
    }
}
