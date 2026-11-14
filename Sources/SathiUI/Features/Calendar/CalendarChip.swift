import SathiCore
import SwiftUI

struct CalendarChip: View {
    let block: CalendarBlock
    let categories: [ActivityCategory]

    var body: some View {
        let look = CalendarBlockLook.of(block.style, categories: categories)
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarChipRadius, style: .continuous)
        Text(verbatim: block.title)
            .font(Typography.tracker(UIMetrics.calendarChipFont, .semibold))
            .foregroundStyle(look.text)
            .lineLimit(1)
            .padding(UIMetrics.calendarChipPadding)
            .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarChipHeight, maxHeight: UIMetrics.calendarChipHeight, alignment: .leading)
            .background(shape.fill(look.fill))
            .overlay(shape.strokeBorder(look.stroke ?? .clear, lineWidth: UIMetrics.cardBorder))
    }
}
