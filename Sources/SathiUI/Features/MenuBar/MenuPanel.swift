import SathiCore
import SwiftUI

package struct MenuPanel: View {
    @EnvironmentObject var e: Engine

    package init() {}

    package var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.menuSpacing) {
            MenuHeader()
            if e.pausedUntil != nil { NapBanner() }
            ForEach(HabitID.allCases.filter { e.enabled($0) }) { id in
                HabitCard(id: id)
            }
            ForEach(HabitID.allCases.filter { !e.enabled($0) }) { id in
                SleepingRow(id: id)
            }
            Spacer(minLength: 0)
            PauseChips()
            MenuFooter()
        }
        .padding(UIMetrics.menuPadding)
        .frame(width: UIMetrics.menuWidth)
        .background(Night.bg)
        .environment(\.colorScheme, .dark)
        .onAppear { e.tick() }
    }
}
