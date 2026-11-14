import SathiCore
import SwiftUI

struct CalendarAccessGate: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: UIMetrics.calendarGateGap) {
            Text(verbatim: Copywriter.calendarGateNotice)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            if engine.calendarAccess == .denied {
                Button(Copywriter.blockOpenSettings) { engine.openCalendarSettings() }
                    .buttonStyle(GhostButton(accent: Night.sprout))
                    .accessibilityIdentifier("calendar.access.open")
            } else {
                Button(Copywriter.blockAllowCalendarAccess) { Task { await engine.requestCalendarAccess() } }
                    .buttonStyle(GhostButton(accent: Night.sprout))
                    .accessibilityIdentifier("calendar.access.allow")
            }
        }
    }
}
