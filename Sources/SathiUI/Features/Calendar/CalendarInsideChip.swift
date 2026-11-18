import SathiCore
import SwiftUI

struct CalendarInsideChip: View {
    let count: Int
    let width: CGFloat

    var body: some View {
        Group {
            if width < UIMetrics.calendarTinyLaneWidth {
                HStack(spacing: UIMetrics.calendarInsideChipGap) {
                    Image(systemName: "square.stack")
                        .font(Typography.tracker(UIMetrics.calendarIconFont, .semibold))
                        .accessibilityHidden(true)
                    Text(verbatim: String(count))
                }
            } else {
                Text(verbatim: Copywriter.calendarInside(count))
            }
        }
        .font(Typography.tracker(UIMetrics.calendarCopiesFont, .bold))
        .foregroundStyle(Night.text)
        .padding(UIMetrics.calendarCopiesPadding)
        .background(Capsule().fill(Night.divider))
        .fixedSize()
        .accessibilityIdentifier("calendar.event.inside")
    }
}
