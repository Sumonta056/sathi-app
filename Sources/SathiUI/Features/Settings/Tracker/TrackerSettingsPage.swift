import SathiCore
import SwiftUI

struct TrackerSettingsPage: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let on = engine.trackerOn.wrappedValue
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            SettingsSubtitle(text: Copywriter.trackerSettingsSubtitle)
            SettingsCard {
                SettingRow(label: Copywriter.trackerOnLabel, showsDivider: false) {
                    BuddySwitch(isOn: engine.trackerOn, accent: Night.tracker, label: Copywriter.trackerOnLabel)
                        .accessibilityIdentifier("settings.tracker.on")
                }
            }
            VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
                TrackerWhenCard()
                DaysOffCard { DaysOffSource.tracker($0) }
                TrackerCategoriesCard()
                TrackerCalendarCard()
                TrackerEventsCard()
                TrackerMoreCard()
            }
            .opacity(on ? 1 : UIMetrics.disabledOpacity)
            .disabled(!on)
        }
        .onAppear { engine.refreshCalendarAccess() }
    }
}
