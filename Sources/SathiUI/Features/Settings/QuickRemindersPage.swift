import SathiCore
import SwiftUI

struct QuickRemindersPage: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let items = e.quickReminders
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            QuickSettingsCard()
            VStack(alignment: .leading, spacing: UIMetrics.quickCardSpacing) {
                header(count: items.count)
                VStack(spacing: 0) {
                    ForEach(items) { QuickRow(item: $0) }
                }
                QuickAddButton()
            }
            .quickCardStyle()
        }
    }

    private func header(count: Int) -> some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Image(systemName: "bell")
                .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                .foregroundStyle(Night.quick)
            Text(verbatim: "Pending")
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            Text(verbatim: "\(count) of \(Limits.quickMax)")
                .font(Typography.pill)
                .foregroundStyle(Night.quick)
                .padding(UIMetrics.quickBadgePadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.quickPillRadius, style: .continuous).fill(Night.quickFill))
        }
        .padding(.bottom, UIMetrics.quickHeaderGap)
    }
}
