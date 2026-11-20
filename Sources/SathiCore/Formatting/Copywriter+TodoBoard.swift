import Foundation

extension Copywriter {
    package static let todoHideLists = "Hide lists"
    package static let todoShowLists = "Show lists"
    package static let todoViewList = "List"
    package static let todoViewBoard = "Board"
    package static let todoViewLabel = "View"
    package static let todoBoardColumnsLabel = "Columns"
    package static let todoBoardColumnsAuto = "Auto"
    package static let todoBoardDropHere = "Drop here"

    package static func todoAddInList(_ list: String) -> String { "In \(list)" }

    package static func todoBoardAdd(list: String) -> String { "Add to-do to \(list)" }

    package static func todoBoardColumns(_ choice: TodoBoardColumnChoice) -> String {
        choice.count.map(String.init) ?? todoBoardColumnsAuto
    }

    package static func todoBoardMove(list: String) -> String { "Drag to move \(list)" }
}
