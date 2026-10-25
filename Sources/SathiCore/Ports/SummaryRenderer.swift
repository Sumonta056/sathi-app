import Foundation

@MainActor
package protocol SummaryRenderer: AnyObject {
    func pdf(for screen: ReportScreen) -> Data?
}
