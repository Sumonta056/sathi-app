import SathiCore
import SwiftUI

struct BlockAccessStatus: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        switch engine.calendarAccess {
        case .allowed:
            HStack(spacing: UIMetrics.blockStatusSpacing) {
                Image(systemName: "checkmark")
                    .font(.system(size: UIMetrics.blockStatusIcon, weight: .heavy))
                Text(verbatim: Copywriter.blockSettingsAllowed)
            }
            .font(Typography.chip)
            .foregroundStyle(Night.sprout)
        case .denied:
            status(Copywriter.blockSettingsNotAllowed) {
                Button(Copywriter.blockOpenSettings) { engine.openCalendarSettings() }
                    .accessibilityIdentifier("settings.block.access.open")
            }
        case .notAsked:
            status(Copywriter.blockSettingsNotAsked) {
                Button(Copywriter.blockSettingsAllowAccess) { Task { await engine.requestCalendarAccess() } }
                    .accessibilityIdentifier("settings.block.access.allow")
            }
        }
    }

    private func status(_ text: String, @ViewBuilder button: () -> some View) -> some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            Text(verbatim: text)
                .font(Typography.chip)
                .foregroundStyle(Night.muted)
            button()
                .buttonStyle(GhostButton(accent: Night.block, height: UIMetrics.blockActionHeight))
        }
    }
}
