import Foundation
import SathiCore

@MainActor
package final class SpyFileExporter: FileExporter {
    package struct Request: Equatable {
        package var suggestedName: String
        package var format: ExportFormat

        package init(suggestedName: String, format: ExportFormat) {
            self.suggestedName = suggestedName
            self.format = format
        }
    }

    package private(set) var requests: [Request] = []
    package var url: URL?
    package var onAsk: () -> Void = {}

    package init(url: URL? = nil) {
        self.url = url
    }

    package func destination(suggestedName: String, format: ExportFormat) async -> URL? {
        requests.append(Request(suggestedName: suggestedName, format: format))
        onAsk()
        return url
    }
}

@MainActor
package final class SpySummaryRenderer: SummaryRenderer {
    package private(set) var screens: [ReportScreen] = []
    package var result: Data?

    package init(result: Data? = nil) {
        self.result = result
    }

    package func pdf(for screen: ReportScreen) -> Data? {
        screens.append(screen)
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
