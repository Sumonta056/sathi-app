import SathiCore
import SwiftUI

enum ReportsTab: CaseIterable {
    case habits, activities

    var title: String {
        switch self {
        case .habits: return Copywriter.trackerTabHabits
        case .activities: return Copywriter.trackerTabActivities
        }
    }
}

enum ActivityRange: CaseIterable {
    case day, month

    var title: String {
        switch self {
        case .day: return Copywriter.trackerRangeDay
        case .month: return Copywriter.trackerRangeMonth
        }
    }
}

struct PillSegment<Option: Hashable>: View {
    let options: [Option]
    @Binding var selected: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let on = option == selected
                Button { selected = option } label: {
                    Text(verbatim: title(option))
                        .font(Typography.chip)
                        .foregroundStyle(on ? Night.text : Night.muted)
                        .padding(UIMetrics.rangeSegmentPadding)
                        .background(Capsule().fill(on ? Night.navSelected : .clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(UIMetrics.rangeSegmentInset)
        .background(Capsule().fill(Night.card))
        .overlay(Pill().strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }
}
