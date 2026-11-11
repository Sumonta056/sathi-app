import SathiCore
import SwiftUI

struct SidebarFooter: View {
    var body: some View {
        HStack(spacing: UIMetrics.sidebarFooterGap) {
            Text(verbatim: Copywriter.sidebarFooter(version: AboutFooter.version))
                .font(Typography.tracker(UIMetrics.sidebarFooterFont, .regular))
                .foregroundStyle(Night.faint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Link(destination: Links.github) { GitHubMark().frame(width: UIMetrics.sidebarLinkIcon, height: UIMetrics.sidebarLinkIcon).frame(
                width: UIMetrics.sidebarLinkSize.width,
                height: UIMetrics.sidebarLinkSize.height
            ) }
            .help(Copywriter.sidebarGitHub)
            .accessibilityLabel(Copywriter.sidebarGitHub)
            Link(destination: Links.portfolio) { globe.frame(width: UIMetrics.sidebarLinkSize.width, height: UIMetrics.sidebarLinkSize.height) }
                .help(Copywriter.sidebarPortfolio)
                .accessibilityLabel(Copywriter.sidebarPortfolio)
        }
        .foregroundStyle(Night.muted)
        .padding(.horizontal, UIMetrics.sidebarFooterPadding)
    }

    private var globe: some View {
        Image(systemName: "globe").font(.system(size: UIMetrics.sidebarLinkIcon, weight: .semibold))
    }
}
