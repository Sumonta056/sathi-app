import SathiCore
import SwiftUI

extension Night {
    static let todo = Color(hex: 0xE58CF5)
    static let todoFill = todo.opacity(0.16)
    static let todoTick = Color(hex: 0x5A6680)
    static let todoRowLine = Color(hex: 0x1C2436)
    static let todoField = Color(hex: 0x1A2233)
    static let todoOverdue = tracker
    static let todoDueToday = spark

    static func todoList(_ hex: String) -> Color {
        guard let c = TodoMapping.rgb(fromHex: hex) else { return muted }
        return Color(.sRGB, red: c.red, green: c.green, blue: c.blue)
    }

    static func todoTile(_ list: TodoSmartList) -> (dot: Color, fill: Color) {
        switch list {
        case .today: (water, Color(hex: 0x1E3350))
        case .scheduled: (tracker, Color(hex: 0x3A2228))
        case .all: (muted, card)
        case .completed: (sprout, card)
        }
    }
}
