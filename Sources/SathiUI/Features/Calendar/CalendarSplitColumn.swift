import SathiCore
import SwiftUI

struct CalendarSplitColumn: View {
    let day: DayKey
    let kind: ReportRange
    let blocks: [CalendarLaidBlock]
    let grid: CalendarGridLayout
    let width: CGFloat
    let now: Date?
    let calendar: Calendar
    let categories: [ActivityCategory]
    var narrow = false
    var calendarNames: [String: String] = [:]
    var actions = CalendarGridActions()
    var popover: Binding<CalendarPopoverTarget?> = .constant(nil)
    var hover: (CalendarLaidBlock, CGRect, Bool) -> Void = { _, _, _ in }

    static func eventColors(_ blocks: [CalendarLaidBlock]) -> [String: Color] {
        Dictionary(blocks.flatMap { [$0] + $0.hidden }.compactMap { b in
            if case let .event(hex) = b.block.style { return (b.id, Color(hex: hex)) }
            return nil
        }) { first, _ in first }
    }

    static func calendarName(_ laid: CalendarLaidBlock, names: [String: String]) -> String? {
        guard case let .event(info) = laid.block.source else { return nil }
        return names[info.calendarID]
    }

    var body: some View {
        let halves = CalendarSplitGeometry.halves(column: width, kind: kind)
        let cards = blocks.filter { !$0.isTodo }
        let colors = Self.eventColors(blocks)
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: width, height: grid.height)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { p in
                    actions.slot(day, CalendarSplitClock.slotStart(y: p.y, grid: grid, day: day, calendar: calendar), p.y)
                }
            if kind == .week { middle(halves) }
            if kind == .day {
                CalendarDayLinks(blocks: cards, actualWidth: halves.actualWidth, planX: halves.planX, colors: colors)
                    .allowsHitTesting(false)
            }
            ForEach(cards) { laid in
                let r = CalendarSplitGeometry.rect(laid, halves: halves)
                card(laid, size: r.size, colors: colors)
                    .background(ring(laid))
                    .contentShape(Rectangle())
                    .onTapGesture { actions.block(day, laid.block, r.minY) }
                    .onHover { hover(laid, r, $0) }
                    .accessibilityIdentifier("calendar.split.block." + laid.id)
                    .offset(x: r.minX, y: r.minY)
            }
            CalendarSplitTodos(todos: blocks.filter(\.isTodo), halves: halves, hover: hover)
            nowLine
        }
        .frame(width: width, height: grid.height, alignment: .topLeading)
        .popover(isPresented: shows, attachmentAnchor: .rect(.rect(anchor)), arrowEdge: .trailing) {
            if let target = popover.wrappedValue {
                CalendarEventPopover(form: target.form) { popover.wrappedValue = nil }
                    .id(target.id)
            }
        }
    }

    @ViewBuilder private func card(_ laid: CalendarLaidBlock, size: CGSize, colors: [String: Color]) -> some View {
        if kind == .day {
            CalendarDayCard(
                laid: laid, size: size, calendar: calendar, categories: categories,
                calendarName: Self.calendarName(laid, names: calendarNames)
            ) { actions.block(day, laid.block, laid.top) }
        } else {
            CalendarWeekBlock(
                laid: laid, size: size, narrow: narrow, calendar: calendar, categories: categories,
                doneColor: laid.doneDuring.flatMap { colors[$0] }
            )
        }
    }

    @ViewBuilder private func ring(_ laid: CalendarLaidBlock) -> some View {
        if kind == .day, laid.isRaised {
            RoundedRectangle(cornerRadius: UIMetrics.calendarEventRadius, style: .continuous)
                .fill(Night.bg)
                .padding(-UIMetrics.calendarRaisedRing)
        }
    }

    private func middle(_ halves: CalendarSplitHalves) -> some View {
        CalendarDashedRule(vertical: true)
            .stroke(Night.border, style: StrokeStyle(lineWidth: UIMetrics.calendarLine, dash: UIMetrics.calendarDashedLine))
            .frame(width: UIMetrics.calendarLine, height: grid.height)
            .offset(x: halves.planX)
            .allowsHitTesting(false)
    }

    @ViewBuilder private var nowLine: some View {
        if let now, CalendarPageDay.interval(of: day, calendar: calendar).contains(now) {
            let y = grid.y(atMinute: CalendarSplitClock.minute(now, day: day, calendar: calendar))
            CalendarNowLine(now: now, calendar: calendar)
                .frame(width: width)
                .position(x: width / 2, y: CGFloat(y))
                .allowsHitTesting(false)
        }
    }

    private var shows: Binding<Bool> {
        Binding(
            get: { popover.wrappedValue?.day == day },
            set: { if !$0, popover.wrappedValue?.day == day { popover.wrappedValue = nil } }
        )
    }

    private var anchor: CGRect {
        CGRect(x: 0, y: popover.wrappedValue?.y ?? 0, width: width, height: UIMetrics.calendarLine)
    }
}

struct CalendarDashedRule: Shape {
    var vertical = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if vertical {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
        return path
    }
}
