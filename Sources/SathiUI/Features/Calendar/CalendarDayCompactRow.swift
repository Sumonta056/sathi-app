import SathiCore
import SwiftUI

struct CalendarDayCompactRow: View {
    let laid: CalendarLaidBlock
    let time: String
    var icon: Color?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarDayMetaGap) {
            if let icon {
                Image(systemName: "calendar")
                    .font(.system(size: UIMetrics.calendarDayIconFont, weight: .semibold))
                    .foregroundStyle(icon)
                    .accessibilityHidden(true)
            }
            CalendarDayParts.title(laid.block.title, lines: 1)
            Spacer(minLength: 0)
            CalendarBlockBadges(laid: laid)
            CalendarDayParts.meta(time, Night.chipText).layoutPriority(1)
            CalendarDayParts.length(laid.rounded)
        }
    }
}
