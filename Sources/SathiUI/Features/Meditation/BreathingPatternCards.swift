import SathiCore
import SwiftUI

struct BreathingPatternCards: View {
    @EnvironmentObject var e: Engine

    private static let beats: [BreathingStyle: String] = Dictionary(uniqueKeysWithValues: BreathingStyle.allCases.map { style in
        (style, BreathingPattern.steps(style).map { "\(Int($0.1))" }.joined(separator: "·"))
    })

    var body: some View {
        let engine = e
        HStack(alignment: .top, spacing: UIMetrics.chipSpacing) {
            ForEach(BreathingStyle.allCases, id: \.self) { style in
                OptionCard(
                    title: Self.title(style),
                    detail: Self.detail(style),
                    isSelected: engine.data.prefs.meditation.style == style,
                    accent: Night.calm,
                    action: { engine.data.prefs.meditation.style = style },
                    top: {
                        Text(verbatim: Self.beats[style] ?? "")
                            .font(Typography.eyebrow)
                            .foregroundStyle(Night.calm)
                    }
                )
            }
        }
    }

    static func title(_ s: BreathingStyle) -> String {
        switch s {
        case .box: return "Box"
        case .relax: return "Wind down"
        case .even: return "Even"
        }
    }

    static func detail(_ s: BreathingStyle) -> String {
        switch s {
        case .box: return "Steady and calm."
        case .relax: return "Good before sleep."
        case .even: return "Simple in and out."
        }
    }
}
