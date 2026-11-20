import SathiCore
import SwiftUI

package struct MenuPanel: View {
    @EnvironmentObject var e: Engine
    package init() {}

    package var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.quickPanelSpacing) {
            QuickHeader()
            QuickNowRow()
            QuickDueTodayCard().todoFinishing { engine, finishing in
                { id in
                    let saved = engine.doneTodo(id)
                    Task {
                        await engine.refreshTodosNow()
                        finishing.resolve(id, failed: !saved, open: Set(engine.todoSnapshot.open.map(\.id)))
                    }
                }
            }
            TimeBlockCard()
            if e.pausedUntil != nil { NapBanner() }
            QuickBuddyList()
            QuickActionRow()
            OpenSathiButton()
            QuickLinks()
        }
        .padding(UIMetrics.quickPanelPadding)
        .frame(width: UIMetrics.quickPanelWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { g in MenuWindowFit(height: g.size.height) })
        .background(Night.bg)
        .environment(\.colorScheme, .dark)
        .onAppear {
            e.tick()
            e.refreshCalendarAccess()
            e.refreshTodos()
        }
    }
}
