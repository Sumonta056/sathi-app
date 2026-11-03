import SathiCore
import SwiftUI

struct CalendarMenu: View {
    @EnvironmentObject var e: Engine
    @Binding var selection: String

    var body: some View {
        let choices = e.calendarChoices()
        Menu {
            ForEach(Self.accounts(choices), id: \.self) { account in
                Section {
                    ForEach(choices.filter { $0.account == account }) { row($0) }
                } header: {
                    Text(verbatim: account)
                }
            }
        } label: {
            label(choices.first { $0.id == selection })
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }

    static func accounts(_ choices: [CalendarChoice]) -> [String] {
        var seen = Set<String>()
        return choices.map(\.account).filter { seen.insert($0).inserted }
    }

    private func row(_ c: CalendarChoice) -> some View {
        Button { selection = c.id } label: {
            Label {
                Text(verbatim: c.title)
            } icon: {
                Image(nsImage: CalendarDot.image(c.colorHex))
            }
        }
    }

    private func label(_ c: CalendarChoice?) -> some View {
        HStack(spacing: UIMetrics.blockMenuSpacing) {
            if let c {
                CalendarDot(hex: c.colorHex)
                Text(verbatim: c.title)
                    .font(Typography.hint)
                    .foregroundStyle(Night.chipText)
                    .lineLimit(1)
                Text(verbatim: "· " + c.account)
                    .font(Typography.hint)
                    .foregroundStyle(Night.faint)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.system(size: UIMetrics.blockChevron, weight: .heavy))
                .foregroundStyle(Night.muted)
        }
        .blockFieldStyle()
    }
}
