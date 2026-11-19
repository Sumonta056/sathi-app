import SwiftUI

struct SidebarBadge: View {
    let count: Int
    let label: String
    let id: String

    var body: some View {
        Text(verbatim: "\(count)")
            .font(Typography.tracker(UIMetrics.sidebarBadgeFont, .bold))
            .monospacedDigit()
            .foregroundStyle(Night.tracker)
            .padding(UIMetrics.sidebarBadgePadding)
            .frame(minWidth: UIMetrics.sidebarBadgeMinWidth)
            .background(Capsule().fill(Night.trackerFill))
            .accessibilityIdentifier(id)
    }
}
