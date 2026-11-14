import SathiCore
import SwiftUI

struct CalendarBlockLook: Equatable {
    let fill: Color
    let stroke: Color?
    let text: Color

    static func of(_ style: CalendarBlockStyle, categories: [ActivityCategory]) -> CalendarBlockLook {
        switch style {
        case let .event(colorHex):
            return CalendarBlockLook(fill: .clear, stroke: Color(hex: colorHex), text: Night.text)
        case let .activity(category):
            let color = ActivityColors.color(category, in: categories)
            return CalendarBlockLook(fill: color.opacity(UIMetrics.calendarActivityTint), stroke: nil, text: Night.text)
        case .away:
            return CalendarBlockLook(fill: Night.calendarAway, stroke: nil, text: Night.muted)
        case .joined:
            return CalendarBlockLook(fill: Night.calendarJoinedFill, stroke: nil, text: Night.calendarJoinedText)
        }
    }
}
