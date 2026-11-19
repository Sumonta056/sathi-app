import SathiCore
import SwiftUI

struct CalendarAccessGate: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let denied = engine.calendarAccess == .denied
        AccessGateCard(
            icon: "calendar",
            accent: Night.sprout,
            title: Copywriter.calendarGateTitle,
            message: denied ? Copywriter.calendarGateDenied : Copywriter.calendarGateNotice,
            button: denied ? Copywriter.blockOpenSettings : Copywriter.blockAllowCalendarAccess,
            buttonID: denied ? "calendar.access.open" : "calendar.access.allow"
        ) {
            if denied { engine.openCalendarSettings() } else { Task { await engine.requestCalendarAccess() } }
        }
    }
}
