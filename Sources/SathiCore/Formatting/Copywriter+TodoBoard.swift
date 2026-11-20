import Foundation

extension Copywriter {
    package static let todoHideLists = "Hide lists"
    package static let todoShowLists = "Show lists"
    package static let todoViewList = "List"
    package static let todoViewBoard = "Board"
    package static let todoViewLabel = "View"

    package static func todoBoardAdd(list: String) -> String { "Add to-do to \(list)" }
}
