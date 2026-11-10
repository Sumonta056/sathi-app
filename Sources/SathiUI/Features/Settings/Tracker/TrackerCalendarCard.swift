import SathiCore
import SwiftUI

struct TrackerCalendarCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        SettingsSection(Copywriter.trackerCalendar) {
            SettingsCard {
                SettingRow(label: Copywriter.trackerCalendar, showsDivider: false) { TrackerAccessStatus() }
                SettingRow(label: Copywriter.trackerCalendarByDefault, hint: Copywriter.trackerCalendarByDefaultHint) {
                    BuddySwitch(isOn: engine.trackerCalendarOnByDefault, accent: Night.tracker, label: Copywriter.trackerCalendarByDefault)
                        .accessibilityIdentifier("settings.tracker.calendar.default")
                }
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

struct TrackerStackedRow<Content: View>: View {
    let label: String
    let hint: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.blockSettingsColumnSpacing) {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: label).font(Typography.rowLabel).foregroundStyle(Night.text)
                Text(verbatim: hint).font(Typography.hint).foregroundStyle(Night.muted).fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: UIMetrics.blockSettingsLabelWidth, alignment: .leading)
            content()
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) { Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight) }
    }
}
