import SathiCore
import SwiftUI

enum CalendarWeekNarrowFace: Equatable {
    case inline
    case stacked
    case titleOnly

    static func pick(width: CGFloat, height: Double) -> CalendarWeekNarrowFace {
        let pad = UIMetrics.calendarWeekNarrowPadding
        if width - pad.leading - pad.trailing < UIMetrics.calendarWeekNarrowTimeRoom { return .titleOnly }
        return height >= UIMetrics.calendarWeekBlockMinHeight ? .stacked : .inline
    }
}

struct CalendarWeekNarrowText: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let calendar: Calendar
    let titleColor: Color

    var body: some View {
        let face = CalendarWeekNarrowFace.pick(width: size.width, height: Double(size.height))
        HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarCopiesGap) {
            switch face {
            case .inline:
                time
                title
            case .stacked:
                VStack(alignment: .leading, spacing: 0) {
                    time
                    title
                }
            case .titleOnly:
                title
            }
            Spacer(minLength: 0)
            CalendarBlockBadges(laid: laid)
        }
        .padding(UIMetrics.calendarWeekNarrowPadding)
    }

    private var time: some View {
        Text(verbatim: Copywriter.calendarStartClock(laid.rounded.start, calendar: calendar))
            .font(Typography.tracker(UIMetrics.calendarWeekTimeFont, .semibold))
            .foregroundStyle(Night.chipText)
            .lineLimit(1)
            .fixedSize()
    }

    private var title: some View {
        Text(verbatim: laid.block.title)
            .font(Typography.tracker(UIMetrics.calendarWeekNarrowFont, .bold))
            .foregroundStyle(titleColor)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
