import SathiCore
import SwiftUI

struct SidebarSettingsRow: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: UIMetrics.mainItemGap) {
                SidebarTile(page: page, size: UIMetrics.sidebarTileSize, iconSize: UIMetrics.sidebarTileIcon)
                Text(verbatim: Copywriter.sidebarSettingsTitle(page))
                    .font(Typography.tracker(UIMetrics.sidebarRowFont, isSelected ? .bold : .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? Night.text : Night.muted)
            .padding(UIMetrics.sidebarRowPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.mainItemRadius, style: .continuous).fill(isSelected ? Night.navSelected : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
