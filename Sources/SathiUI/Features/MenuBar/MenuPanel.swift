import SathiCore
import SwiftUI

package struct MenuPanel: View {
    @EnvironmentObject var e: Engine
    package init() {}

    package var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.menuSpacing) {
            MenuHeader()
            if e.pausedUntil != nil { NapBanner() }
            MenuCards()
            MenuFooter()
        }
        .padding(UIMetrics.menuPadding)
        .frame(width: UIMetrics.menuWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { g in MenuWindowFit(height: g.size.height) })
        .background(Night.bg)
        .environment(\.colorScheme, .dark)
        .onAppear {
            e.tick()
            e.refreshCalendarAccess()
        }
    }
}
