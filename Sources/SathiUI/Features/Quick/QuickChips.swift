import SathiCore
import SwiftUI

extension View {
    func quickCardStyle() -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
        return padding(UIMetrics.cardPadding)
            .background(shape.fill(Night.card))
            .overlay(shape.strokeBorder(Night.quickBorder, lineWidth: UIMetrics.cardBorder))
    }
}

struct QuickChips: View {
    let selected: Int?
    let pick: (Int) -> Void

    static func title(_ minutes: Int) -> String {
        minutes % 60 == 0 ? "\(minutes / 60) hour" : "\(minutes) min"
    }

    var body: some View {
        HStack(spacing: UIMetrics.quickChipSpacing) {
            ForEach(Limits.quickChips, id: \.self) { minutes in
                chip(minutes)
            }
        }
    }

    private func chip(_ minutes: Int) -> some View {
        let on = selected == minutes
        let shape = RoundedRectangle(cornerRadius: UIMetrics.quickChipRadius, style: .continuous)
        return Button { pick(minutes) } label: {
            Text(verbatim: Self.title(minutes))
                .font(Typography.pill)
                .foregroundStyle(on ? Night.onAccent : Night.chipText)
                .frame(maxWidth: .infinity, minHeight: UIMetrics.quickChipHeight)
                .background(shape.fill(on ? Night.quick : Night.bg))
                .overlay(shape.strokeBorder(on ? Color.clear : Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
