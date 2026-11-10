import SathiCore
import SwiftUI

struct TrackerCalendarRow: View {
    @Binding var draft: ActivityDraft
    let calendars: [CalendarChoice]
    let defaultID: String?
    var size = TrackerSize.corner

    var body: some View {
        HStack(spacing: size.toggleGap) {
            checkBox
            Text(verbatim: Copywriter.trackerAddToCalendar)
                .font(Typography.tracker(size.body, .semibold))
                .foregroundStyle(Night.text)
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
        let shape = RoundedRectangle(cornerRadius: size.checkRadius, style: .continuous)
        return Button { draft.calendarID = isOn ? nil : defaultChoice?.id } label: {
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

    private var menu: some View {
        let chosen = calendars.first { $0.id == draft.calendarID } ?? defaultChoice
        let shape = RoundedRectangle(cornerRadius: size.dropRadius, style: .continuous)
        return Menu {
            ForEach(accounts, id: \.self) { account in
                Section {
                    ForEach(calendars.filter { $0.account == account }) { item($0) }
                } header: {
                    Text(verbatim: account)
                }
            }
        } label: {
            HStack(spacing: size.dropGap) {
                if let chosen {
                    CalendarDot(hex: chosen.colorHex, size: size.dot)
                    Text(verbatim: chosen.title)
                        .font(Typography.tracker(size.label, .semibold))
                        .foregroundStyle(Night.chipText)
                        .lineLimit(1)
                }
                TrackerChevron(size: size.chevron)
            }
            .padding(.horizontal, size.dropPadding)
            .frame(height: size.chipHeight)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
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
