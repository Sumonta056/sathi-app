import SathiCore
import SwiftUI

struct TrackerWhenCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        SettingsSection(Copywriter.trackerWhenToAsk) {
            SettingsCard {
                SettingRow(label: Copywriter.trackerHours, hint: Copywriter.trackerHoursHint, showsDivider: false) {
                    HStack(spacing: UIMetrics.chipSpacing) {
                        Text(verbatim: Copywriter.trackerFrom).font(Typography.hint).foregroundStyle(Night.muted)
                        TimeMenu(minutes: engine.trackerStartMinutes, accent: Night.tracker)
                        Text(verbatim: Copywriter.trackerTo).font(Typography.hint).foregroundStyle(Night.muted)
                        TimeMenu(minutes: engine.trackerEndMinutes, accent: Night.tracker)
                    }
                }
                SettingRow(label: Copywriter.trackerDays, hint: Copywriter.trackerDaysHint) {
                    let days = engine.trackerWeekdays
                    ChipRow(
                        options: Weekday.allCases,
                        accent: Night.tracker,
                        isSelected: { days.wrappedValue.contains($0) },
                        onTap: { engine.toggleTrackerWeekday($0) },
                        label: \.shortLabel,
                        spokenLabel: \.name,
                        identifier: { "settings.tracker.day.\($0.name.lowercased())" }
                    )
                }
                SettingRow(label: Copywriter.trackerAskEvery, hint: Copywriter.trackerAskEveryHint) {
                    minutesChips(Limits.trackerAskChips, engine.trackerAskEvery, prefix: "ask")
                }
                SettingRow(label: Copywriter.trackerUsualLength, hint: Copywriter.trackerUsualLengthHint) {
                    ChipRow(
                        options: ActivityLength.choices,
                        accent: Night.tracker,
                        isSelected: { $0 == engine.trackerUsualLength.wrappedValue },
                        onTap: { engine.trackerUsualLength.wrappedValue = $0 },
                        label: Copywriter.trackerLengthLabel,
                        identifier: { "settings.tracker.length.\($0.minutes.map(String.init) ?? "open")" }
                    )
                }
                SettingRow(label: Copywriter.trackerAwayAfter, hint: Copywriter.trackerAwayAfterHint) {
                    minutesChips(Limits.idleChips, engine.trackerIdle, prefix: "idle")
                }
            }
        }
    }

    private func minutesChips(_ options: [Int], _ binding: Binding<Int>, prefix: String) -> some View {
        ChipRow(
            options: options,
            accent: Night.tracker,
            isSelected: { $0 == binding.wrappedValue },
            onTap: { binding.wrappedValue = $0 },
            label: Copywriter.trackerMinutesChip,
            identifier: { "settings.tracker.\(prefix).\($0)" }
        )
    }
}
