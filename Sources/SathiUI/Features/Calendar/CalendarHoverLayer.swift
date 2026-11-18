import SathiCore
import SwiftUI

struct CalendarHoverLayer: View {
    @ObservedObject var host: CalendarHoverHost
    let grid: CalendarGridActions
    let height: CGFloat
    @EnvironmentObject var e: Engine

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let target = host.shown {
                    ring(target)
                    card(target, width: geo.size.width)
                }
                if let target = host.todoEdit { todoAnchor(target) }
            }
        }
    }

    private func ring(_ t: CalendarHoverTarget) -> some View {
        RoundedRectangle(cornerRadius: t.radius, style: .continuous)
            .strokeBorder(Night.text, lineWidth: UIMetrics.calendarHoverRing)
            .frame(width: t.rect.width, height: t.rect.height)
            .offset(x: t.rect.minX, y: t.rect.minY)
            .allowsHitTesting(false)
            .accessibilityIdentifier("calendar.hover.ring")
    }

    private func card(_ t: CalendarHoverTarget, width: CGFloat) -> some View {
        let info = e.calendarHoverInfo(t.laid, among: t.among)
        let run = CalendarHoverRun(engine: e, grid: grid) { host.todoEdit = $0 }
        return CalendarHoverCard(info: info, actions: info.actions) { action in
            host.close()
            run.run(action, t)
        } pick: { id in
            host.close()
            run.open(row: id, t)
        }
        .onHover { host.card($0) }
        .offset(
            x: CalendarHoverPlacement.x(block: t.rect, card: UIMetrics.calendarHoverWidth, width: width, prefersLeft: t.prefersLeft),
            y: CalendarHoverPlacement.y(block: t.rect, height: height)
        )
    }

    private func todoAnchor(_ t: CalendarHoverTarget) -> some View {
        Color.clear
            .frame(width: t.rect.width, height: t.rect.height)
            .popover(isPresented: editing, arrowEdge: .trailing) {
                if case let .todo(id) = t.laid.block.source {
                    CalendarTodoPopover(todoID: id) { host.todoEdit = nil }
                        .environmentObject(e)
                }
            }
            .offset(x: t.rect.minX, y: t.rect.minY)
            .allowsHitTesting(false)
    }

    private var editing: Binding<Bool> {
        Binding(get: { host.todoEdit != nil }, set: { if !$0 { host.todoEdit = nil } })
    }
}
