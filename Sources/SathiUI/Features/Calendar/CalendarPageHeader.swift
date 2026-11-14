import SathiCore
import SwiftUI

struct CalendarPageHeader: View {
    @Binding var range: CalendarPageRange
    let now: Date
    let calendar: Calendar

    var body: some View {
        PageHeaderLayout(gap: UIMetrics.reportsGap) {
            titleBlock
            HStack(spacing: UIMetrics.reportsGap) {
                PillSegment(options: ReportRange.allCases, selected: kind, title: Copywriter.rangeSegment)
                HStack(spacing: UIMetrics.rangeBarGap) {
                    arrow("chevron.left", Copywriter.rangePrevious) { range = range.previous }
                    todayButton
                    arrow("chevron.right", Copywriter.rangeNext) { range = range.next }
                }
            }
            .fixedSize()
        }
    }

    private var titleBlock: some View {
        let title = Copywriter.calendarRangeTitle(range, calendar: calendar)
        return VStack(alignment: .leading, spacing: UIMetrics.calendarHeaderSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarTitleGap) {
                Text(verbatim: title.main)
                    .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                    .foregroundStyle(Night.text)
                Text(verbatim: title.year)
                    .font(Typography.tracker(UIMetrics.mainPageTitleFont, .regular))
                    .foregroundStyle(Night.muted)
            }
            .lineLimit(1)
            .fixedSize()
            Text(verbatim: Copywriter.calendarDayBoundary)
                .font(Typography.tracker(UIMetrics.calendarNoteFont, .semibold))
                .foregroundStyle(Night.faint)
        }
    }

    private var kind: Binding<ReportRange> {
        Binding(get: { range.kind }, set: { range = range.changed(to: $0, now: now) })
    }

    private var todayButton: some View {
        Button { range = .containing(now, kind: range.kind, calendar: calendar) } label: {
            Text(verbatim: Copywriter.calendarToday)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .padding(UIMetrics.calendarTodayPadding)
                .frame(height: UIMetrics.rangeArrowSize)
                .background(shape.fill(Night.card))
                .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
    }

    private func arrow(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .frame(width: UIMetrics.rangeArrowSize, height: UIMetrics.rangeArrowSize)
                .background(shape.fill(Night.card))
                .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.rangeArrowRadius, style: .continuous)
    }
}
