import SathiCore
import SwiftUI

struct CalendarSplitLines: View {
    let grid: CalendarGridLayout
    let showsFoldText: Bool
    var columns = 0
    var width: CGFloat = 0
    var planX: CGFloat?

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
                let dividers = verticals(at: { CGFloat($0) * width }, height: size.height)
                ctx.stroke(dividers, with: .color(Night.divider), lineWidth: UIMetrics.calendarLine)
                if let planX {
                    let middles = verticals(at: { CGFloat($0) * width + planX }, height: size.height)
                    ctx.stroke(
                        middles, with: .color(Night.border),
                        style: StrokeStyle(lineWidth: UIMetrics.calendarLine, dash: UIMetrics.calendarDashedLine)
                    )
                }
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

    private func verticals(at x: (Int) -> CGFloat, height: CGFloat) -> Path {
        var p = Path()
        for i in 0 ..< columns {
            let left = x(i) + UIMetrics.calendarLine / 2
            p.move(to: CGPoint(x: left, y: 0))
            p.addLine(to: CGPoint(x: left, y: height))
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
        .background(Night.card)
        .accessibilityIdentifier("calendar.fold")
    }
}
