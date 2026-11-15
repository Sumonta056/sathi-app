import Foundation

package enum TodoSelection: Hashable, Sendable {
    case smart(TodoSmartList)
    case list(String)
}
