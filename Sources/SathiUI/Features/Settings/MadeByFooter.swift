import SwiftUI

struct MadeByFooter: View {
    var body: some View {
        HStack(spacing: UIMetrics.creditSpacing) {
            Text(verbatim: "Made by Sumonta")
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            Text(verbatim: "·")
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
            Link(destination: Links.github) {
                GitHubMark()
                    .frame(width: UIMetrics.creditIconSize, height: UIMetrics.creditIconSize)
            }
            .help("GitHub")
            .accessibilityLabel("GitHub")
            Link(destination: Links.portfolio) {
                Image(systemName: "globe")
                    .font(.system(size: UIMetrics.creditIconSize, weight: .semibold))
            }
            .help("Portfolio")
            .accessibilityLabel("Portfolio")
        }
        .foregroundStyle(Night.muted)
        .fixedSize()
        .padding(UIMetrics.navPadding)
    }
}
