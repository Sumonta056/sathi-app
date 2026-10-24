import SathiCore
import SwiftUI

struct ContainerSegment: View {
    @Binding var selection: Container

    var body: some View {
        HStack(spacing: 0) {
            option(.glass, "Glass")
            option(.bottle, "Sip bottle")
        }
        .padding(UIMetrics.segmentInset)
        .background(track.fill(Night.sidebar))
        .overlay(track.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }

    private func option(_ c: Container, _ title: String) -> some View {
        let on = selection == c
        return Button { selection = c } label: {
            Text(title)
                .font(Typography.chip)
                .foregroundStyle(on ? Night.text : Night.muted)
                .padding(.horizontal, UIMetrics.chipPadding)
                .frame(height: UIMetrics.segmentHeight)
                .background(thumb.fill(on ? Night.border : Color.clear))
                .contentShape(thumb)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var track: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.segmentRadius, style: .continuous)
    }

    private var thumb: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.segmentRadius - UIMetrics.segmentInset, style: .continuous)
    }
}
