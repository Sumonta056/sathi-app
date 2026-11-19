import SathiCore
import SwiftUI

struct CalendarHalfDividers: Equatable {
    var solid: [CGFloat] = []
    var dashed: [CGFloat] = []
}

struct CalendarSplitLines: View {
    let grid: CalendarGridLayout
    let showsFoldText: Bool
    var columns = 0
    var width: CGFloat = 0
    var kind: ReportRange = .month

    static func halfDividers(kind: ReportRange, column: CGFloat, columns: Int) -> CalendarHalfDividers {
        guard kind != .month else { return CalendarHalfDividers() }
        let halves = CalendarSplitGeometry.halves(column: column, kind: kind)
        let starts = (0 ..< columns).map { CGFloat($0) * column }
        return CalendarHalfDividers(
            solid: kind == .day ? starts.map { $0 + halves.actualWidth } : [],
            dashed: starts.map { $0 + halves.planX }
        )
    }

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
                let halves = Self.halfDividers(kind: kind, column: width, columns: columns)
                let dividers = verticals((0 ..< columns).map { CGFloat($0) * width } + halves.solid, height: size.height)
                ctx.stroke(dividers, with: .color(Night.divider), lineWidth: UIMetrics.calendarLine)
                ctx.stroke(
                    verticals(halves.dashed, height: size.height), with: .color(Night.border),
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

    private func verticals(_ xs: [CGFloat], height: CGFloat) -> Path {
        var p = Path()
        for x in xs {
            let left = x + UIMetrics.calendarLine / 2
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
