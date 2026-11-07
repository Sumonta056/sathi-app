import SathiCore
import SwiftUI

struct VolumeSlider: View {
    @Binding var value: Double
    let accent: Color
    let label: String

    var body: some View {
        Slider(value: $value, in: Limits.sessionVolume)
            .tint(accent)
            .frame(width: UIMetrics.volumeSliderWidth)
            .accessibilityLabel(Text(verbatim: label))
    }
}
