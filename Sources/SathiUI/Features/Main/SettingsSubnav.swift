import SathiCore
import SwiftUI

struct SettingsSubnav: View {
    let selected: SettingsPage
    let select: (SettingsPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.mainSubnavSpacing) {
            ForEach(SettingsPage.all, id: \.self) { page in
                item(page)
            }
        }
        .padding(UIMetrics.mainSubnavPadding)
        .overlay(alignment: .leading) {
            Rectangle().fill(Night.divider).frame(width: UIMetrics.dividerHeight)
        }
        .padding(.leading, UIMetrics.mainSubnavIndent)
    }

    private func item(_ page: SettingsPage) -> some View {
        let on = page == selected
        return Button { select(page) } label: {
            Text(verbatim: Copywriter.settingsPageTitle(page))
                .font(Typography.tracker(UIMetrics.mainSubItemFont, on ? .bold : .regular))
                .foregroundStyle(on ? accent(page) : Night.muted)
                .padding(UIMetrics.mainSubItemPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func accent(_ page: SettingsPage) -> Color {
        switch page {
        case let .habit(id): return Night.accent(id)
        case .general, .quickReminders, .tracker, .timeBlocks, .sound: return Night.water
        }
    }
}
