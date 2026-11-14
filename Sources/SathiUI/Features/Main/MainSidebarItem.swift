import SwiftUI

struct MainSidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var tag: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: UIMetrics.mainItemGap) {
                Image(systemName: icon)
                    .font(.system(size: UIMetrics.mainItemIconSize))
                    .frame(width: UIMetrics.mainItemIconSize, height: UIMetrics.mainItemIconSize)
                Text(verbatim: title)
                    .font(Typography.tracker(UIMetrics.mainItemFont, isSelected ? .semibold : .medium))
                Spacer(minLength: 0)
                if let tag { ExperimentalTag(text: tag) }
            }
            .foregroundStyle(isSelected ? Night.text : Night.muted)
            .padding(UIMetrics.mainItemPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.mainItemRadius, style: .continuous).fill(isSelected ? Night.navSelected : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
