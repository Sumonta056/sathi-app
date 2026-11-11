import AppKit
import SathiCore
import SwiftUI

struct QuickLinks: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack {
            link(Copywriter.quickPanelReports) { e.openReports() }
            Spacer()
            link(Copywriter.quickPanelSettings) { e.openSettings() }
            Spacer()
            link(Copywriter.quickPanelQuit) { NSApp.terminate(nil) }
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
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
    }
}
