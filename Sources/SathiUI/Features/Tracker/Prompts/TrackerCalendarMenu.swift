import SathiCore
import SwiftUI

struct TrackerCalendarMenu: View {
    @Binding var draft: ActivityDraft
    let calendars: [CalendarChoice]
    let chosen: CalendarChoice?
    let size: TrackerSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.dropRadius, style: .continuous)
        Menu {
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
