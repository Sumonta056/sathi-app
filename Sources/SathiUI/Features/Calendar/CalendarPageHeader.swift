import SathiCore
import SwiftUI

struct CalendarPageHeader: View {
    @Binding var range: CalendarPageRange
    let now: Date
    let calendar: Calendar
    var stats: CalendarPageStats?
    var sidePanelShown = true
    var toggleSidePanel: () -> Void = {}
    var rowMinutes: Binding<Int>?
    var today: ((ReportRange) -> CalendarPageRange)?
    var weekDays: Int?
    var pickDays: (Int) -> Void = { _ in }

    var body: some View {
        CalendarHeaderLayout(gap: UIMetrics.reportsGap) {
            titleBlock
            if let stats { CalendarHeaderSummary(stats: stats) }
            HStack(spacing: UIMetrics.reportsGap) {
                PillSegment(options: ReportRange.allCases, selected: kind, title: Copywriter.rangeSegment)
                HStack(spacing: UIMetrics.rangeBarGap) {
                    arrow("chevron.left", Copywriter.rangePrevious) { range = range.previous }
                    todayButton
                    arrow("chevron.right", Copywriter.rangeNext) { range = range.next }
                }
                if let weekDays, range.kind == .week { CalendarWeekDaysControl(days: weekDays, pick: pickDays) }
                if let rowMinutes, range.kind != .month { CalendarRowZoom(minutes: rowMinutes) }
                arrow("sidebar.right", Copywriter.calendarSidePanelLabel(shown: sidePanelShown), action: toggleSidePanel)
            }
            .fixedSize()
        }
    }

    private var titleBlock: some View {
        let title = Copywriter.calendarRangeTitle(range, calendar: calendar)
        return HStack(alignment: .firstTextBaseline, spacing: UIMetrics.calendarTitleGap) {
            Text(verbatim: title.main)
                .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                .foregroundStyle(Night.text)
            Text(verbatim: title.year)
                .font(Typography.tracker(UIMetrics.mainPageTitleFont, .regular))
                .foregroundStyle(Night.muted)
        }
        .lineLimit(1)
        .fixedSize()
    }

    private var kind: Binding<ReportRange> {
        Binding(get: { range.kind }, set: { range = range.changed(to: $0, now: now) })
    }

    private var todayButton: some View {
        Button { range = today?(range.kind) ?? .containing(now, kind: range.kind, calendar: calendar, weekDays: range.weekDays) } label: {
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
