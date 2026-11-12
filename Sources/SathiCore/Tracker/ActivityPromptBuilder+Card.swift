import Foundation

extension ActivityPromptBuilder {
    static func runningCard(_ r: RunningActivity, now: Date, calendar: Calendar) -> PromptCard {
        let elapsed = max(0, now.timeIntervalSince(r.start))
        let minutes = Int(elapsed / Timing.minute)
        return PromptCard(
            tag: Copywriter.activityPromptNowRunning, text: r.text, category: r.category,
            detail: Copywriter.activityPromptCardDetail(start: r.start, minutes: minutes, length: r.expectedLength.minutes, calendar: calendar),
            progress: r.expectedLength.interval.map { $0 > 0 ? min(1, elapsed / $0) : 1 }
        )
    }

    static func lastCard(_ s: TrackerPromptState) -> PromptCard? {
        s.resume.map {
            PromptCard(
                tag: Copywriter.activityPromptLastActivity, text: $0.text, category: $0.category,
                detail: s.lastEnded.map { Copywriter.activityPromptEnded($0.text, at: $0.end, calendar: s.calendar) } ?? ""
            )
        }
    }

    static func backCard(_ s: TrackerPromptState, detail: String) -> PromptCard? {
        s.lastActivity.map {
            PromptCard(tag: Copywriter.activityPromptBeforeYouLeft, text: $0.text, category: $0.category, detail: detail)
        }
    }
}
