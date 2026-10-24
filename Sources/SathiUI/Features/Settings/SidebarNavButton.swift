import SwiftUI

struct SidebarNavButton<Accessory: View>: View {
    let title: String
    let icon: String
    let tint: Color
    var textColor = Night.text
    let tab: SettingsTab
    @Binding var selection: SettingsTab
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        let on = selection == tab
        Button { selection = tab } label: {
            HStack(spacing: UIMetrics.sectionSpacing) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: UIMetrics.navIconSize, height: UIMetrics.navIconSize)
                Text(verbatim: title)
                    .font(Typography.rowLabel)
                    .foregroundStyle(textColor)
                accessory()
                Spacer(minLength: 0)
            }
            .padding(UIMetrics.navPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(on ? Night.navSelected : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

extension SidebarNavButton where Accessory == EmptyView {
    init(title: String, icon: String, tint: Color, textColor: Color = Night.text, tab: SettingsTab, selection: Binding<SettingsTab>) {
        self.init(title: title, icon: icon, tint: tint, textColor: textColor, tab: tab, selection: selection) { EmptyView() }
    }
}
