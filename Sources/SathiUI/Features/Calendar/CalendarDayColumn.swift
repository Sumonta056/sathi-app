import SathiCore
import SwiftUI

struct CalendarDayColumn: View {
    let day: DayKey
    let placed: [CalendarPlacedBlock]
    let texts: [String: CalendarBlockText]
    let math: CalendarGridMath
    let now: Date?
    let categories: [ActivityCategory]
    let calendar: Calendar
    var actions = CalendarGridActions()
    var selected: Set<ActivityID> = []
    var popover: Binding<CalendarPopoverTarget?> = .constant(nil)

    var body: some View {
        GeometryReader { geo in
            let width = max(0, geo.size.width - 2 * UIMetrics.calendarColumnInset)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: geo.size.width, height: math.totalHeight)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { p in actions.slot(day, math.slotStart(y: p.y), p.y) }
                ForEach(placed, id: \.block.id) { p in
                    let indent = min(CGFloat(p.depth) * UIMetrics.calendarCascadeIndent, width / 2)
                    let lane = (width - indent) / CGFloat(max(1, p.lanes))
                    let y = math.y(for: p.span.start)
                    blockView(p, y: y)
                        .frame(width: p.isBackdrop ? width : max(0, lane - UIMetrics.calendarLaneGap))
                        .offset(x: UIMetrics.calendarColumnInset + indent + lane * CGFloat(p.lane), y: y)
                }
                ForEach(placed.filter(\.isBackdrop), id: \.block.id) { p in
                    let y = math.y(for: p.span.start)
                    backdrop(p, y: y, layer: .label)
                        .frame(width: width)
                        .offset(x: UIMetrics.calendarColumnInset, y: y)
                }
                if let now, math.holds(now) {
                    CalendarNowLine(now: now, calendar: calendar)
                        .frame(width: geo.size.width)
                        .position(x: geo.size.width / 2, y: math.y(for: now))
                        .allowsHitTesting(false)
                }
            }
            .popover(isPresented: shows, attachmentAnchor: .rect(.rect(anchor(width: geo.size.width))), arrowEdge: .trailing) {
                if let target = popover.wrappedValue {
                    CalendarEventPopover(form: target.form) { popover.wrappedValue = nil }
                        .id(target.id)
                }
            }
        }
        .frame(height: math.totalHeight)
    }

    @ViewBuilder private func blockView(_ p: CalendarPlacedBlock, y: CGFloat) -> some View {
        if case .todo = p.block.source {
            CalendarTodoChip(block: p.block)
        } else if p.isBackdrop {
            backdrop(p, y: y, layer: .stripes)
        } else {
            Button { actions.press(day, p.block, y) } label: {
                CalendarBlockView(
                    block: p.block, text: texts[p.block.id] ?? CalendarBlockText(time: "", spoken: p.block.title),
                    height: math.height(p.span), categories: categories,
                    selected: CalendarMergePick.id(of: p.block).map(selected.contains) ?? false,
                    raised: p.depth > 0
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func backdrop(_ p: CalendarPlacedBlock, y: CGFloat, layer: CalendarAwayBackdrop.Layer) -> some View {
        CalendarAwayBackdrop(
            block: p.block, text: texts[p.block.id] ?? CalendarBlockText(time: "", spoken: p.block.title),
            height: math.height(p.span), layer: layer,
            selected: CalendarMergePick.id(of: p.block).map(selected.contains) ?? false
        ) { actions.press(day, p.block, y) }
    }

    private var shows: Binding<Bool> {
        Binding(
            get: { popover.wrappedValue?.day == day },
            set: { if !$0, popover.wrappedValue?.day == day { popover.wrappedValue = nil } }
        )
    }

    private func anchor(width: CGFloat) -> CGRect {
        CGRect(x: 0, y: popover.wrappedValue?.y ?? 0, width: width, height: UIMetrics.calendarLine)
    }
}
