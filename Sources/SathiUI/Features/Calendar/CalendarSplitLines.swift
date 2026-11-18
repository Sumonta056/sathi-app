import SathiCore
import SwiftUI

struct CalendarSplitLines: View {
    let grid: CalendarGridLayout
    let showsFoldText: Bool

    var body: some View {
        let marks = CalendarSplitClock.marks(grid)
        ZStack(alignment: .topLeading) {
            Canvas { ctx, size in
                ctx.stroke(path(marks.filter(\.isHour), width: size.width), with: .color(Night.divider), lineWidth: UIMetrics.calendarLine)
                ctx.stroke(
                    path(marks.filter { !$0.isHour }, width: size.width),
                    with: .color(Night.divider.opacity(UIMetrics.calendarSubLineOpacity)),
                    style: StrokeStyle(lineWidth: UIMetrics.calendarLine, dash: UIMetrics.calendarDashedLine)
                )
            }
            ForEach(Array(grid.rows.enumerated()).filter(\.element.isFold), id: \.offset) { _, row in
                fold(row).offset(y: CGFloat(row.top))
            }
        }
        .frame(height: CGFloat(grid.height), alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func path(_ marks: [CalendarGridMark], width: CGFloat) -> Path {
        var p = Path()
        for m in marks {
            p.move(to: CGPoint(x: 0, y: m.y))
            p.addLine(to: CGPoint(x: width, y: m.y))
        }
        return p
    }

    private func fold(_ row: CalendarGridRow) -> some View {
        ZStack(alignment: .leading) {
            CalendarStripes()
            if showsFoldText {
                Text(verbatim: Copywriter.calendarFoldText(fromMinute: row.startMinute, toMinute: row.endMinute))
                    .font(Typography.tracker(UIMetrics.calendarFoldFont, .semibold))
                    .foregroundStyle(Night.faint)
                    .lineLimit(1)
                    .padding(.horizontal, UIMetrics.calendarFoldPadding)
            }
        }
        .frame(maxWidth: .infinity, minHeight: CGFloat(row.height), maxHeight: CGFloat(row.height))
        .accessibilityIdentifier("calendar.fold")
    }
}
