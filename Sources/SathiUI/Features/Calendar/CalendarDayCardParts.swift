import SathiCore
import SwiftUI

enum CalendarDayParts {
    static func title(_ text: String, lines: Int, color: Color = Night.text) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarDayTitleFont, .bold))
            .foregroundStyle(color)
            .lineLimit(lines)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
    }

    static func length(_ span: DateInterval, color: Color = Night.text) -> some View {
        Text(verbatim: Copywriter.calendarBlockLength(span))
            .font(Typography.tracker(UIMetrics.calendarDayTitleFont, .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
    }

    static func meta(_ text: String, _ color: Color, weight: Font.Weight = .semibold) -> some View {
        Text(verbatim: text)
            .font(Typography.tracker(UIMetrics.calendarDayMetaFont, weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    static func tag(_ text: String, icon: Bool, color: Color) -> some View {
        HStack(spacing: UIMetrics.calendarDayTagGap) {
            if icon {
                Image(systemName: "calendar")
                    .font(.system(size: UIMetrics.calendarDayIconFont))
                    .accessibilityHidden(true)
            }
            Text(verbatim: text)
        }
        .font(Typography.tracker(UIMetrics.calendarDayMetaFont, .semibold))
        .foregroundStyle(color)
        .lineLimit(1)
    }

    static func pencil(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.activitiesPencilRadius, style: .continuous)
        return Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: UIMetrics.activitiesPencilIcon, weight: .semibold))
                .foregroundStyle(Night.chipText)
                .frame(width: UIMetrics.activitiesPencil, height: UIMetrics.activitiesPencil)
                .background(shape.fill(Night.card))
                .overlay(shape.strokeBorder(tint.opacity(UIMetrics.activitiesPencilTint), lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: Copywriter.calendarDayEditLabel(title)))
        .accessibilityIdentifier("calendar.day.edit")
    }
}
