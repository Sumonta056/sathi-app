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
