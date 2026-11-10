import SathiCore
import SwiftUI

struct TrackerAccessStatus: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        switch engine.calendarAccess {
        case .allowed:
            Text(verbatim: Copywriter.trackerCalendarAllowed)
                .font(Typography.chip)
                .foregroundStyle(Night.sprout)
        case .denied:
            status(Copywriter.blockSettingsNotAllowed, Copywriter.blockOpenSettings, "settings.tracker.access.open") {
                engine.openCalendarSettings()
            }
        case .notAsked:
            status(Copywriter.blockSettingsNotAsked, Copywriter.blockSettingsAllowAccess, "settings.tracker.access.allow") {
                Task { await engine.requestCalendarAccess() }
            }
        }
    }

    private func status(_ text: String, _ button: String, _ id: String, _ action: @escaping () -> Void) -> some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            Text(verbatim: text).font(Typography.chip).foregroundStyle(Night.muted)
            Button(button, action: action)
                .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.blockActionHeight))
                .accessibilityIdentifier(id)
        }
    }
}
