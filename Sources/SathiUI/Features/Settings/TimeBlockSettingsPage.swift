import SathiCore
import SwiftUI

struct TimeBlockSettingsPage: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            PageTitle(title: Copywriter.blockSettingsTitle, subtitle: Copywriter.blockSettingsSubtitle)
            SettingsCard {
                SettingRow(label: Copywriter.blockSettingsAccess, showsDivider: false) {
                    BlockAccessStatus()
                }
                BlockDefaultCalendarRow()
                SettingRow(label: Copywriter.blockSettingsDisplay) {
                    ChipRow(
                        options: TimeBlockDisplay.allCases,
                        accent: Night.block,
                        isSelected: { $0 == engine.blockDisplay.wrappedValue },
                        onTap: { engine.blockDisplay.wrappedValue = $0 },
                        label: Self.label,
                        identifier: { "settings.block.display.\($0.rawValue)" }
                    )
                }
                SettingRow(label: Copywriter.blockSettingsSound, hint: Copywriter.blockSettingsSoundHint) {
                    BuddySwitch(isOn: engine.blockPlaysSound, accent: Night.block, label: Copywriter.blockSettingsSound)
                        .accessibilityIdentifier("settings.block.sound")
                }
            }
        }
        .onAppear {
            engine.refreshCalendarAccess()
            if engine.calendarAccess == .notAsked { Task { await engine.requestCalendarAccess() } }
        }
    }

    static func label(_ display: TimeBlockDisplay) -> String {
        switch display {
        case .menuBar: return Copywriter.blockSettingsMenuBar
        case .widget: return Copywriter.blockSettingsWidget
        }
    }
}
