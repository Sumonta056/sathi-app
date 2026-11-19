import SathiCore
import SwiftUI

struct CalendarDayEventFace: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let time: String
    let calendarName: String?

    private var hex: UInt32 {
        if case let .event(colorHex) = laid.block.style { return colorHex }
        return NightHex.trackerEvent
    }

    var body: some View {
        let color = Color(hex: hex)
        let text = Color(hex: CalendarDayTextColor.hex(hex))
        HStack(alignment: .top, spacing: UIMetrics.calendarDayRowGap) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarDayLineGap) {
                HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarDayIconGap) {
                    Image(systemName: "calendar")
                        .font(.system(size: UIMetrics.calendarDayIconFont, weight: .semibold))
                        .foregroundStyle(text)
                        .accessibilityHidden(true)
                    CalendarDayParts.title(laid.block.title, lines: CalendarDayCardFit.titleLines(height: size.height))
                    Spacer(minLength: 0)
                    CalendarBlockBadges(laid: laid)
                }
                HStack(spacing: UIMetrics.calendarDayMetaGap) {
                    CalendarDayParts.meta(time, Night.chipText).layoutPriority(2)
                    if let calendarName {
                        CalendarDayParts.meta(calendarName, text, weight: .bold).layoutPriority(1)
                    }
                    if laid.doneDuringCount > 0 {
                        CalendarDayParts.tag(Copywriter.calendarDayDoneDuring(laid.doneDuringCount), icon: false, color: Night.faint)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CalendarDayParts.length(laid.rounded)
        }
        .modifier(CalendarDayChrome(
            size: size, fill: Night.card, edge: color,
            outline: color.opacity(UIMetrics.calendarDayEventOutlineOpacity)
        ))
    }
}
