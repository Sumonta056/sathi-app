import Foundation

package enum TodoAddRule {
    package static func titleAfterAdd(current: String, sent: String, result: TodoWriteResult) -> String {
        guard case .done = result, current == sent else { return current }
        return ""
    }
}
