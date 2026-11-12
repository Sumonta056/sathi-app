import SathiCore
import SwiftUI

struct ActivitiesTextButton: View {
    let label: String
    let title: String
    let copyLabel: String
    let text: () -> String
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            Text(verbatim: label)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .padding(UIMetrics.rangeSegmentPadding)
                .frame(height: UIMetrics.rangeArrowSize)
                .background(shape.fill(Night.card))
                .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $open) {
            ActivityTextSheet(title: title, text: text(), copyLabel: copyLabel) { open = false }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
