import Foundation
import SathiCore

package struct DecodedBackup: Decodable {
    package var schemaVersion: Int
    package var exportedAt: Date
    package var prefs: Prefs
    package var live: LiveState
    package var events: [HistoryEvent]
    package var activities: [Activity]?

    package static func decode(_ data: Data) -> DecodedBackup? {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try? d.decode(DecodedBackup.self, from: data)
    }
}
