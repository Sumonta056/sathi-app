import SathiCore
import SwiftUI

struct TrackerCategoriesCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let list = engine.activityCategories
        let full = list.count >= Limits.categoryMax
        SettingsSection(Copywriter.trackerCategories) {
            SettingsCard {
                VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
                    TrackerFlowLayout(spacing: UIMetrics.chipSpacing) {
                        ForEach(list) { TrackerCategoryChip(category: $0) }
                        if !full { addButton }
                    }
                    if full {
                        Text(verbatim: Copywriter.trackerCategoriesFull)
                            .font(Typography.hint)
                            .foregroundStyle(Night.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(UIMetrics.rowPadding)
            }
        }
    }

    private var addButton: some View {
        let engine = e
        return Button { engine.addActivityCategory(Self.newName(engine.activityCategories), colorHex: engine.nextCategoryColor()) } label: {
            Text(verbatim: Copywriter.trackerAddCategory)
                .font(Typography.chip)
                .foregroundStyle(Night.tracker)
                .padding(UIMetrics.trackerCategoryChipPadding)
                .overlay(Pill().strokeBorder(Night.tracker, style: StrokeStyle(lineWidth: UIMetrics.chipBorder, dash: [UIMetrics.dashLength])))
                .contentShape(Pill())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.tracker.category.add")
    }

    static func newName(_ list: [ActivityCategory]) -> String {
        let taken = Set(list.map { $0.name.lowercased() })
        let base = Copywriter.trackerNewCategory
        if !taken.contains(base.lowercased()) { return base }
        return (2 ... Limits.categoryMax + 1).map { "\(base) \($0)" }.first { !taken.contains($0.lowercased()) } ?? base
    }
}
