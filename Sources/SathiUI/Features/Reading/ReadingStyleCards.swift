import SathiCore
import SwiftUI

struct ReadingStyleCards: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        OptionCardRow {
            ForEach(ReadingReminderStyle.allCases, id: \.self) { style in
                OptionCard(
                    title: Self.title(style),
                    detail: Self.detail(style),
                    isSelected: engine.data.prefs.reading.reminderStyle == style,
                    accent: Night.reading,
                    action: { engine.data.prefs.reading.reminderStyle = style },
                    top: {
                        Image(systemName: Self.icon(style))
                            .foregroundStyle(Night.reading)
                            .accessibilityHidden(true)
                    }
                )
            }
        }
    }

    static func title(_ s: ReadingReminderStyle) -> String {
        switch s {
        case .corner: return "Corner popup"
        case .focus: return "Focus screen"
        }
    }

    static func detail(_ s: ReadingReminderStyle) -> String {
        switch s {
        case .corner: return "A small card in the top-right. Keep working while it waits."
        case .focus: return "Dims the screen and starts the timer. For deep reading nights."
        }
    }

    static func icon(_ s: ReadingReminderStyle) -> String {
        switch s {
        case .corner: return "rectangle.inset.topright.filled"
        case .focus: return "moon.stars.fill"
        }
    }
}
