import SathiCore
import SwiftUI

struct IntervalRow: View {
    @Binding var minutes: Int
    let accent: Color

    private var rows: [[Int]] {
        stride(from: 0, to: Limits.intervalChips.count, by: UIMetrics.intervalChipsPerRow).map {
            Array(Limits.intervalChips[$0 ..< min($0 + UIMetrics.intervalChipsPerRow, Limits.intervalChips.count)])
        }
    }

    var body: some View {
        SettingRow(label: "Remind me every", showsDivider: false) {
            VStack(alignment: .trailing, spacing: UIMetrics.chipSpacing) {
                ForEach(rows, id: \.self) { row in
                    ChipRow(
                        options: row,
                        accent: accent,
                        isSelected: { $0 == minutes },
                        onTap: { minutes = $0 },
                        label: { "\($0) min" },
                        chipWidth: UIMetrics.intervalChipWidth
                    )
                }
            }
        }
    }
}
