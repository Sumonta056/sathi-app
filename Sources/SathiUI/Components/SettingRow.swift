import SwiftUI

struct SettingRow<Trailing: View>: View {
    let label: String
    var hint: String?
    var showsDivider = true
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                labels
                Spacer()
                trailing().fixedSize()
            }
            VStack(alignment: .trailing, spacing: UIMetrics.sectionSpacing) {
                HStack {
                    labels
                    Spacer(minLength: 0)
                }
                trailing().fixedSize()
            }
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            if showsDivider {
                Rectangle()
                    .fill(Night.divider)
                    .frame(height: UIMetrics.dividerHeight)
            }
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            Text(verbatim: label)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
                .fixedSize()
            if let hint {
                Text(verbatim: hint)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .fixedSize()
            }
        }
    }
}
