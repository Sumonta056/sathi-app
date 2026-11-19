import SathiCore
import SwiftUI

struct CalendarDayActivityFace: View {
    let laid: CalendarLaidBlock
    let activity: Activity
    let size: CGSize
    let time: String
    let categories: [ActivityCategory]
    let edit: () -> Void

    var body: some View {
        let hex = ActivityColors.hex(activity.category, in: categories)
        let color = Color(hex: hex)
        let fill = RGB(hex: NightHex.card).mix(RGB(hex: hex), UIMetrics.calendarDayActivityTint).color()
        HStack(alignment: .top, spacing: UIMetrics.calendarDayRowGap) {
            VStack(alignment: .leading, spacing: UIMetrics.calendarDayLineGap) {
                HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarDayIconGap) {
                    CalendarDayParts.title(laid.block.title, lines: CalendarDayCardFit.titleLines(height: size.height))
                    Spacer(minLength: 0)
                    CalendarBlockBadges(laid: laid)
                }
                HStack(spacing: UIMetrics.calendarDayMetaGap) {
                    CalendarDayParts.meta(time, Night.chipText).layoutPriority(2)
                    if let category = activity.category {
                        CalendarDayParts.meta(category, color, weight: .bold).layoutPriority(1)
                    }
                    tag
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CalendarDayParts.length(laid.rounded)
            CalendarDayParts.pencil(laid.block.title, tint: color, action: edit)
        }
        .modifier(CalendarDayChrome(size: size, fill: fill, edge: color))
    }

    @ViewBuilder private var tag: some View {
        if activity.eventID != nil {
            CalendarDayParts.tag(Copywriter.calendarDayInCalendar, icon: true, color: Night.trackerEvent)
        } else {
            CalendarDayParts.tag(Copywriter.calendarDayNotInCalendar, icon: true, color: Night.faint)
        }
    }
}
