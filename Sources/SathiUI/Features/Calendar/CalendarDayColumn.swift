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
    var showsAwayPill = true
    var hover: ((CalendarHoverTarget, Bool) -> Void)?
    var weekSides = false
    @State private var stripe: CalendarHoverTarget?

    var body: some View {
        GeometryReader { geo in
            let width = max(0, geo.size.width - 2 * UIMetrics.calendarColumnInset)
            let frames = frames(width: width, originX: geo.frame(in: .named(CalendarHoverHost.space)).minX)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: geo.size.width, height: math.totalHeight)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { p in actions.slot(day, math.slotStart(y: p.y), p.y) }
                    .onContinuousHover(coordinateSpace: .local) { stripeHover($0, frames) }
                ForEach(placed.filter { !CalendarTodoLayer.holds($0) }, id: \.block.id) { p in
                    let rect = frames.rect(p)
                    blockView(p, y: rect.minY, frames)
                        .frame(width: rect.width)
                        .offset(x: rect.minX, y: rect.minY)
                }
                ForEach(showsAwayPill ? placed.filter(\.isBackdrop) : [], id: \.block.id) { p in
                    let y = math.y(for: p.displaySpan.start)
                    backdrop(p, y: y, layer: .label)
                        .onHover { send(frames.target(p), $0) }
                        .frame(width: width)
                        .offset(x: UIMetrics.calendarColumnInset, y: y)
                }
                CalendarTodoLayer(placed: placed, math: math, width: width) { send(frames.target($0), $1) }
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

    @ViewBuilder private func blockView(_ p: CalendarPlacedBlock, y: CGFloat, _ frames: CalendarHoverFrames) -> some View {
        if p.isBackdrop {
            backdrop(p, y: y, layer: .stripes)
        } else if Self.isEvent(p) {
            CalendarEventCard(placed: p, math: math, context: context(frames))
        } else {
            CalendarActivityBlock(placed: p, height: math.height(p.displaySpan), context: context(frames), y: y)
        }
    }

    static func isEvent(_ p: CalendarPlacedBlock) -> Bool {
        if case .event = p.block.source { return true }
        return false
    }

    private func context(_ frames: CalendarHoverFrames) -> CalendarBlockContext {
        CalendarBlockContext(
            texts: texts, categories: categories, selected: selected,
            press: { block, y in actions.press(day, block, y) },
            hover: { send(frames.target($0), $1) }
        )
    }

    private func frames(width: CGFloat, originX: CGFloat) -> CalendarHoverFrames {
        CalendarHoverFrames(
            day: day, placed: placed, math: math, width: width, originX: originX,
            prefersLeft: weekSides && CalendarHoverPlacement.prefersLeft(day: day, calendar: calendar)
        )
    }

    private func send(_ target: CalendarHoverTarget, _ inside: Bool) {
        hover?(target, inside)
    }

    private func stripeHover(_ phase: HoverPhase, _ frames: CalendarHoverFrames) {
        var next: CalendarHoverTarget?
        if case let .active(point) = phase { next = frames.stripe(at: point.y).map(frames.target) }
        guard next?.id != stripe?.id else { return }
        if let stripe { send(stripe, false) }
        if let next { send(next, true) }
        stripe = next
    }

    private func backdrop(_ p: CalendarPlacedBlock, y: CGFloat, layer: CalendarAwayBackdrop.Layer) -> some View {
        CalendarAwayBackdrop(
            block: p.block, text: texts[p.block.id] ?? CalendarBlockText(time: "", spoken: p.block.title),
            height: math.height(p.displaySpan), layer: layer,
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
