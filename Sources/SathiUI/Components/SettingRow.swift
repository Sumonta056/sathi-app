import SwiftUI

struct SettingRow<Trailing: View>: View {
    let label: String
    var hint: String?
    var showsDivider = true
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                Text(verbatim: label)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                if let hint {
                    Text(verbatim: hint)
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                }
            }
            Spacer()
            trailing()
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
}
