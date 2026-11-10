import SathiCore
import SwiftUI

struct TrackerCalendarRow: View {
    @Binding var draft: ActivityDraft
    let calendars: [CalendarChoice]
    let defaultID: String?

    var body: some View {
        HStack(spacing: UIMetrics.trackerOptionRowSpacing) {
            checkBox
            Text(verbatim: Copywriter.trackerAddToCalendar)
                .font(Typography.hint)
                .foregroundStyle(Night.chipText)
            Spacer(minLength: 0)
            menu
        }
        .opacity(calendars.isEmpty ? UIMetrics.trackerDisabledOpacity : 1)
        .allowsHitTesting(!calendars.isEmpty)
    }

    private var isOn: Bool { draft.calendarID != nil }

    private var defaultChoice: CalendarChoice? {
        calendars.first { $0.id == defaultID } ?? calendars.first
    }

    private var checkBox: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerCheckRadius, style: .continuous)
        return Button { draft.calendarID = isOn ? nil : defaultChoice?.id } label: {
            ZStack {
                shape.fill(isOn ? Night.tracker : Color.clear)
                shape.strokeBorder(isOn ? Night.tracker : Night.fieldBorder, lineWidth: UIMetrics.trackerChipSelectedBorder)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: UIMetrics.trackerCheckMark, weight: .black))
                        .foregroundStyle(Night.onAccent)
                }
            }
            .frame(width: UIMetrics.trackerCheckBox, height: UIMetrics.trackerCheckBox)
            .contentShape(shape)
            .accessibilityIdentifier("tracker.calendar.check")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: Copywriter.trackerAddToCalendar))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var menu: some View {
        let chosen = calendars.first { $0.id == draft.calendarID } ?? defaultChoice
        return Menu {
            ForEach(accounts, id: \.self) { account in
                Section {
                    ForEach(calendars.filter { $0.account == account }) { item($0) }
                } header: {
                    Text(verbatim: account)
                }
            }
        } label: {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                if let chosen {
                    CalendarDot(hex: chosen.colorHex)
                    Text(verbatim: chosen.title)
                        .font(Typography.hint)
                        .foregroundStyle(Night.chipText)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: UIMetrics.blockChevron, weight: .heavy))
                    .foregroundStyle(Night.muted)
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .opacity(isOn ? 1 : UIMetrics.trackerDisabledOpacity)
    }

    private var accounts: [String] {
        var seen = Set<String>()
        return calendars.map(\.account).filter { seen.insert($0).inserted }
    }

    private func item(_ c: CalendarChoice) -> some View {
        Button { draft.calendarID = c.id } label: {
            Label {
                Text(verbatim: c.title)
            } icon: {
                Image(nsImage: CalendarDot.image(c.colorHex))
            }
        }
    }
}
