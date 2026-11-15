import SwiftUI

struct TrackerStackedRow<Content: View>: View {
    let label: String
    let hint: String
    @ViewBuilder let content: () -> Content
    @Environment(\.mainLayout) private var layout

    var body: some View {
        Group {
            if layout.isNarrow {
                VStack(alignment: .leading, spacing: UIMetrics.blockSettingsColumnSpacing) {
                    labels
                    content()
                }
                .accessibilityIdentifier(MainLayout.stackedIdentifier)
            } else {
                HStack(alignment: .top, spacing: UIMetrics.blockSettingsColumnSpacing) {
                    labels.frame(width: UIMetrics.blockSettingsLabelWidth, alignment: .leading)
                    content()
                }
            }
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) { Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight) }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            Text(verbatim: label).font(Typography.rowLabel).foregroundStyle(Night.text)
            Text(verbatim: hint).font(Typography.hint).foregroundStyle(Night.muted).fixedSize(horizontal: false, vertical: true)
        }
    }
}
