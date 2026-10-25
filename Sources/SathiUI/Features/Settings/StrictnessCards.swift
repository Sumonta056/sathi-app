import SathiCore
import SwiftUI

struct StrictnessCards: View {
    let options: [Strictness]
    let selected: Strictness
    let accent: Color
    let onSelect: (Strictness) -> Void

    var body: some View {
        OptionCardRow {
            ForEach(options) { s in
                OptionCard(title: s.title, detail: s.detail, isSelected: s == selected, accent: accent, action: { onSelect(s) }, top: {
                    LevelDots(level: s.level, total: Strictness.allCases.count, accent: accent)
                })
            }
        }
    }
}

struct LevelDots: View {
    let level: Int
    let total: Int
    let accent: Color

    var body: some View {
        HStack(spacing: UIMetrics.dotSpacing) {
            ForEach(1 ... total, id: \.self) { i in
                Circle()
                    .fill(i <= level ? accent : Night.switchOff)
                    .frame(width: UIMetrics.dotSize, height: UIMetrics.dotSize)
            }
        }
        .accessibilityHidden(true)
    }
}
