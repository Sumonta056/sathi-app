import SathiCore
import SwiftUI

struct RangeSegment: View {
    @Binding var range: ReportRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReportRange.allCases, id: \.self) { option in
                let on = option == range
                Button { range = option } label: {
                    Text(verbatim: Self.title(option))
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

    static func title(_ range: ReportRange) -> String {
        switch range {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
}
