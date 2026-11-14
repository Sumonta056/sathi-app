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
                    let lane = width / CGFloat(max(1, p.lanes))
                    let y = math.y(for: p.span.start)
                    Button { actions.block(day, p.block, y) } label: {
                        CalendarBlockView(
                            block: p.block, text: texts[p.block.id] ?? CalendarBlockText(time: "", spoken: p.block.title),
                            height: math.height(p.span), categories: categories
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: max(0, lane - UIMetrics.calendarLaneGap))
                    .offset(x: UIMetrics.calendarColumnInset + lane * CGFloat(p.lane), y: y)
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
