import Foundation

@MainActor
package protocol FileExporter: AnyObject {
    func destination(suggestedName: String, format: ExportFormat) async -> URL?
}
