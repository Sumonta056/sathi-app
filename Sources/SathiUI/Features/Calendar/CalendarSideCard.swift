import SwiftUI

struct CalendarSideCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        VStack(alignment: .leading, spacing: UIMetrics.calendarSideCardSpacing) {
            Text(verbatim: title)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            content
        }
        .padding(UIMetrics.calendarSideCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }
}
