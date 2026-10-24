import SwiftUI

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(verbatim: text.uppercased())
            .font(Typography.sectionLabel)
            .tracking(UIMetrics.labelTracking)
            .foregroundStyle(Night.label)
    }
}
