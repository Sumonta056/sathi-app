import AppKit
import SathiCore
import SwiftUI

struct QuickLinks: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack {
            link(Copywriter.quickPanelReports, id: "quick.reports") { e.openReports() }
            Spacer()
            link(Copywriter.quickPanelSettings, id: "quick.settings") { e.openSettings() }
            Spacer()
            link(Copywriter.quickPanelQuit, id: "quick.quit") { NSApp.terminate(nil) }
        }
    }

    private func link(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button {
            MenuBarWindow.close()
            action()
        } label: {
            Text(verbatim: title)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .padding(.vertical, UIMetrics.quickLinkPadding)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
