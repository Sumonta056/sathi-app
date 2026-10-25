import SwiftUI

struct ReportsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            content()
        }
        .padding(UIMetrics.reportsCardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(shape.fill(Night.card))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
