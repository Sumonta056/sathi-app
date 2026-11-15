import SathiCore
import SwiftUI

struct BlockDefaultCalendarRow: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        TrackerStackedRow(label: Copywriter.blockSettingsDefaultCalendar, hint: Copywriter.blockSettingsDefaultHint) {
            if e.calendarAccess == .allowed {
                BlockDefaultCalendarList()
            } else {
                Text(verbatim: Copywriter.blockSettingsNeedsAccess)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
