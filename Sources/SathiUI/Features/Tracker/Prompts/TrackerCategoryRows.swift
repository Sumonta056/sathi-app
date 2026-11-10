import SathiCore
import SwiftUI

struct TrackerCategoryRows: View {
    let categories: [ActivityCategory]
    let selected: String?
    let idPrefix: String
    let onPick: (String) -> Void

    private static let perRow = 3

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerChipSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: UIMetrics.trackerChipSpacing) {
                    ForEach(row) { category in
                        TrackerChip(
                            label: category.name,
                            on: selected == category.name,
                            id: idPrefix + category.name,
                            dot: category.colorHex
                        ) { onPick(category.name) }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rows: [[ActivityCategory]] {
        stride(from: 0, to: categories.count, by: Self.perRow).map {
            Array(categories[$0 ..< min($0 + Self.perRow, categories.count)])
        }
    }
}
