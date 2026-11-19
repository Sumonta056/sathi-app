import SwiftUI

struct SidebarHeading: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
            .font(Typography.tracker(UIMetrics.sidebarHeadingFont, .heavy))
            .tracking(UIMetrics.sidebarHeadingTracking)
            .foregroundStyle(Night.faint)
            .padding(UIMetrics.sidebarHeadingPadding)
    }
}
