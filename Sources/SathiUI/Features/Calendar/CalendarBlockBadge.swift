import SathiCore
import SwiftUI

struct CalendarBlockBadge: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarCopiesFont, .bold))
            .foregroundStyle(Night.onAccent)
            .padding(UIMetrics.calendarCopiesPadding)
            .background(Capsule().fill(Night.text))
            .fixedSize()
    }
}

struct CalendarBlockBadges: View {
    let laid: CalendarLaidBlock

    var body: some View {
        if laid.block.copies > 1 { CalendarBlockBadge(text: Copywriter.calendarCopies(laid.block.copies)) }
        if !laid.hidden.isEmpty { CalendarBlockBadge(text: Copywriter.calendarHiddenCount(laid.hidden.count)) }
    }
}
