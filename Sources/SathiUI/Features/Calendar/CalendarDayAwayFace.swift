import SathiCore
import SwiftUI

struct CalendarDayAwayFace: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let time: String
    let edit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.calendarDayRowGap) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarDayLineGap) {
                HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarDayIconGap) {
                    CalendarDayParts.title(laid.block.title, lines: 1, color: Night.muted)
                    Spacer(minLength: 0)
                    CalendarBlockBadges(laid: laid)
                }
                CalendarDayParts.meta(time, Night.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CalendarDayParts.length(laid.rounded, color: Night.muted)
            CalendarDayParts.pencil(laid.block.title, tint: Night.trackerAway, action: edit)
        }
        .modifier(CalendarDayChrome(
            size: size, padding: UIMetrics.calendarDayAwayPadding, fill: Night.card, edge: Night.trackerAway,
            outline: Night.border, stripes: true
        ))
    }
}
