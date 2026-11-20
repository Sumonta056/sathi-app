import SathiCore
import SwiftUI

struct TrackerCalendarCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        SettingsSection(Copywriter.trackerCalendar) {
            SettingsCard {
                SettingRow(label: Copywriter.trackerCalendar, showsDivider: false) { TrackerAccessStatus() }
                TrackerStackedRow(label: Copywriter.trackerDefaultCalendar, hint: Copywriter.trackerDefaultCalendarHint) {
                    if engine.calendarAccess == .allowed {
                        TrackerCalendarList(
                            choices: engine.calendarChoices(),
                            isOn: { $0 == engine.data.prefs.tracker.defaultCalendarID },
                            onTap: { engine.setTrackerDefaultCalendar($0) },
                            identifier: "settings.tracker.calendar"
                        )
                    } else {
                        Text(verbatim: Copywriter.blockSettingsNeedsAccess)
                            .font(Typography.hint)
                            .foregroundStyle(Night.faint)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
