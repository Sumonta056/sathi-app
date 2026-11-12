import SwiftUI

struct PageHeader<Controls: View>: View {
    let title: String
    @ViewBuilder let controls: () -> Controls

    var body: some View {
        PageHeaderLayout(gap: UIMetrics.reportsGap) {
            Text(verbatim: title)
                .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                .foregroundStyle(Night.text)
                .lineLimit(1)
                .fixedSize()
            HStack(spacing: UIMetrics.reportsGap) { controls() }
                .fixedSize()
        }
    }
}
