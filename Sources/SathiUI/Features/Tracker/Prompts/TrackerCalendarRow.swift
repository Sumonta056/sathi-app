import SathiCore
import SwiftUI

struct TrackerCalendarRow: View {
    @Binding var draft: ActivityDraft
    let calendars: [CalendarChoice]
    let defaultID: String?
    let access: CalendarAccess
    let onAllow: () -> Void
    let onOpenSettings: () -> Void
    var size = TrackerSize.corner

    var body: some View {
        HStack(spacing: size.toggleGap) {
            if access != .denied { checkBox }
            Text(verbatim: Copywriter.trackerAddToCalendar)
                .font(Typography.tracker(size.body, .semibold))
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            trailing
        }
        .frame(minHeight: size.chipHeight)
        .opacity(isOff ? UIMetrics.trackerDisabledOpacity : 1)
        .allowsHitTesting(!isOff)
    }

    private var isOn: Bool { draft.calendarID != nil }
    private var isOff: Bool { access == .allowed && calendars.isEmpty }

    private var defaultChoice: CalendarChoice? {
        calendars.first { $0.id == defaultID } ?? calendars.first
    }

    @ViewBuilder private var trailing: some View {
        switch access {
        case .denied:
            Button(action: onOpenSettings) {
                Text(verbatim: Copywriter.blockOpenSettings)
                    .font(Typography.tracker(size.label, .semibold))
                    .foregroundStyle(Night.tracker)
                    .accessibilityIdentifier("tracker.calendar.openSettings")
            }
            .buttonStyle(.plain)
        case .allowed where calendars.isEmpty:
            Text(verbatim: Copywriter.trackerNoCalendars)
                .font(Typography.tracker(size.label, .semibold))
                .foregroundStyle(Night.muted)
                .lineLimit(1)
                .accessibilityIdentifier("tracker.calendar.none")
        case .allowed:
            let chosen = calendars.first { $0.id == draft.calendarID } ?? defaultChoice
            TrackerCalendarMenu(draft: $draft, calendars: calendars, chosen: chosen, size: size)
                .opacity(isOn ? 1 : UIMetrics.trackerDisabledOpacity)
        case .notAsked:
            EmptyView()
        }
    }

    private func tick() {
        guard access == .allowed else { return onAllow() }
        draft.calendarID = isOn ? nil : defaultChoice?.id
    }

    private var checkBox: some View {
        let shape = RoundedRectangle(cornerRadius: size.checkRadius, style: .continuous)
        return Button(action: tick) {
            ZStack {
                shape.fill(isOn ? Night.tracker : Color.clear)
                shape.strokeBorder(isOn ? Night.tracker : Night.fieldBorder, lineWidth: UIMetrics.trackerChipSelectedBorder)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size.checkMark, weight: .black))
                        .foregroundStyle(Night.trackerOnAccent)
                }
            }
            .frame(width: size.check, height: size.check)
            .contentShape(shape)
            .accessibilityIdentifier("tracker.calendar.check")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: Copywriter.trackerAddToCalendar))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
