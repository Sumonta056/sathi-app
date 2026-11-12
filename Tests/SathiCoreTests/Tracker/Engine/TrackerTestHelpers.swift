import Foundation
import SathiCore
import SathiTestSupport

extension EngineHarness {
    func work(_ text: String = "Code review", minutes: Int? = 30, offset: Int = 0, quiet: Bool = false) -> ActivityDraft {
        ActivityDraft(
            text: text,
            category: "Coding",
            length: minutes.map(ActivityLength.minutes) ?? .open,
            askOffsetMinutes: offset,
            quiet: quiet
        )
    }

    func start(_ text: String = "Code review", minutes: Int? = 30, offset: Int = 0, quiet: Bool = false, at switchAt: Date? = nil) {
        engine.startActivity(work(text, minutes: minutes, offset: offset, quiet: quiet), switchAt: switchAt)
    }

    var saved: [Activity] { activities.all.sorted { $0.start < $1.start } }
    var promptKind: PromptKind? { engine.trackerPrompt?.kind }
    var trackerShows: [PromptKind] { presenter.shownPrompts }
    var tinks: Int { sound.played.count { $0 == .trackerPrompt } }
}

func wed(_ h: Int, _ m: Int = 0, s: Int = 0) -> Date {
    day(2026, 3, 4, h, m).addingTimeInterval(TimeInterval(s))
}
