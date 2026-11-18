import SathiCore
import SwiftUI

struct CalendarBlockLook: Equatable {
    let fill: Color
    let stroke: Color?
    let text: Color

    static func of(_ style: CalendarBlockStyle, categories: [ActivityCategory]) -> CalendarBlockLook {
        switch style {
        case let .event(colorHex):
            return CalendarBlockLook(fill: Night.card, stroke: Color(hex: colorHex), text: Night.text)
        case let .activity(category), let .joined(category):
            let hex = ActivityColors.hex(category, in: categories)
            let mixed = RGB(hex: NightHex.card).mix(RGB(hex: hex), UIMetrics.calendarActivityTint).color()
            return CalendarBlockLook(fill: mixed, stroke: nil, text: Night.text)
        case .away:
            return CalendarBlockLook(fill: Night.calendarAway, stroke: nil, text: Night.muted)
        case let .todo(colorHex):
            return CalendarBlockLook(fill: .clear, stroke: Color(hex: colorHex), text: Night.text)
        }
    }
}
