import SathiCore
import SwiftUI

struct QuickListCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let items = e.quickReminders
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: UIMetrics.quickCardSpacing) {
                header(count: items.count)
                rows(items)
                addRow
            }
            .quickCardStyle()
        }
    }

    private func header(count: Int) -> some View {
        HStack(spacing: UIMetrics.chipSpacing) {
            Image(systemName: "bell")
                .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                .foregroundStyle(Night.quick)
            Text(verbatim: "Quick reminders")
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

    @ViewBuilder private func rows(_ items: [QuickReminder]) -> some View {
        if items.count > UIMetrics.quickVisibleRows {
            ScrollView { list(items) }
                .frame(height: CGFloat(UIMetrics.quickVisibleRows) * UIMetrics.quickRowHeight)
        } else {
            list(items)
        }
    }

    private func list(_ items: [QuickReminder]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { QuickRow(item: $0) }
        }
    }

    private var addRow: some View {
        Button { e.openQuickAdd() } label: {
            HStack(spacing: UIMetrics.quickTimeSpacing) {
                Image(systemName: "plus")
                    .font(.system(size: UIMetrics.quickIconSize, weight: .heavy))
                Text(verbatim: "Quick reminder")
                    .font(Typography.rowLabel)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Night.quick)
            .padding(.horizontal, UIMetrics.chipPadding)
            .frame(height: UIMetrics.quickAddHeight)
            .overlay(
                RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                    .strokeBorder(Night.quickBorder, style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: [UIMetrics.dashLength]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, UIMetrics.quickCardSpacing)
    }
}
