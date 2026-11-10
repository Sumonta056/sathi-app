import SathiCore
import SwiftUI

struct TrackerEventsCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let reads = engine.trackerReadsEvents.wrappedValue
        SettingsSection(Copywriter.trackerCalendarEvents) {
            SettingsCard {
                SettingRow(label: Copywriter.trackerUseEvents, showsDivider: false) {
                    BuddySwitch(isOn: engine.trackerReadsEvents, accent: Night.tracker, label: Copywriter.trackerUseEvents)
                        .accessibilityIdentifier("settings.tracker.events.on")
                }
                if reads { details }
            }
        }
    }

    @ViewBuilder private var details: some View {
        let engine = e
        let choices = engine.readableCalendarChoices()
        let ticked = engine.data.prefs.tracker.readCalendarIDs
        TrackerStackedRow(label: Copywriter.trackerReadCalendars, hint: Copywriter.trackerReadCalendarsHint) {
            if engine.calendarAccess == .allowed {
                TrackerCalendarList(
                    choices: choices,
                    isOn: { ticked.contains($0) },
                    onTap: { engine.toggleReadCalendar($0) },
                    identifier: "settings.tracker.read"
                )
            } else {
                VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
                    Text(verbatim: Copywriter.blockSettingsNeedsAccess)
                        .font(Typography.hint)
                        .foregroundStyle(Night.faint)
                    TrackerAccessStatus()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        SettingRow(label: Copywriter.trackerWhenEventStarts, hint: Copywriter.trackerWhenEventStartsHint) {
            ChipRow(
                options: [EventMode.logAndTell, .askFirst],
                accent: Night.tracker,
                isSelected: { $0 == engine.trackerEventMode.wrappedValue },
                onTap: { engine.trackerEventMode.wrappedValue = $0 },
                label: Copywriter.trackerEventMode,
                identifier: { "settings.tracker.eventmode.\($0.rawValue)" }
            )
        }
        let rows = choices.filter { ticked.contains($0.id) }
        if !rows.isEmpty {
            TrackerStackedRow(label: Copywriter.trackerCategoryPerCalendar, hint: Copywriter.trackerCategoryPerCalendarHint) {
                VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
                    ForEach(rows) { TrackerCalendarCategoryRow(calendar: $0) }
                }
            }
        }
    }
}

struct TrackerCalendarCategoryRow: View {
    let calendar: CalendarChoice
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let current = engine.data.prefs.tracker.categoryByCalendar[calendar.id]
        HStack(spacing: UIMetrics.blockListRowSpacing) {
            CalendarDot(hex: calendar.colorHex, size: UIMetrics.blockListDot)
            Text(verbatim: calendar.title).font(Typography.chip).foregroundStyle(Night.text).lineLimit(1)
            Spacer(minLength: 0)
            Menu {
                Button(calendar.title + Copywriter.trackerCalendarNameSuffix) { engine.setCategory(forCalendar: calendar.id, to: nil) }
                ForEach(engine.activityCategories) { c in
                    Button(c.name) { engine.setCategory(forCalendar: calendar.id, to: c.name) }
                }
            } label: {
                Text(verbatim: current ?? calendar.title + Copywriter.trackerCalendarNameSuffix)
                    .font(Typography.chip)
                    .foregroundStyle(Night.tracker)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityIdentifier("settings.tracker.calendarcategory.\(calendar.id)")
        }
    }
}
