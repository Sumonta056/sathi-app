import AppKit
import SathiCore
import SwiftUI

package struct MenuPanel: View {
    @EnvironmentObject var e: Engine

    package init() {}

    package var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sathi").font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text(e.now.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ForEach(HabitID.allCases) { id in
                if e.enabled(id) { HabitRow(id: id) }
            }
            Divider().padding(.top, 2)
            MenuItem(title: e.pausedUntil == nil ? "Pause reminders for 1 hour" : "Resume reminders") {
                if e.pausedUntil == nil { e.pause() } else { e.resume() }
            }
            MenuItem(title: "Settings…") {
                MenuBarWindow.close()
                e.openSettings()
            }
            MenuItem(title: "Quit Sathi") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: UIMetrics.menuWidth)
        .onAppear { e.tick() }
    }
}
