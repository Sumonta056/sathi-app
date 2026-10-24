import Foundation

package protocol FileExporter: AnyObject {
    @discardableResult
    func save(_ data: Data, suggestedName: String, format: ExportFormat) -> Bool
}
