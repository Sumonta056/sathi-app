import SathiCore
import SwiftUI

package struct MenuPanel: View {
    @EnvironmentObject var e: Engine
    package init() {}

    package var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.quickPanelSpacing) {
            QuickHeader()
            QuickNowRow()
            QuickDueTodayCard().todoFinishing { engine, finishing in { if !engine.doneTodo($0) { finishing.fail($0) } } }
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
