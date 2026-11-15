import Foundation

extension Engine {
    func promptSwitchTimes(_ p: PromptState, now: Date) -> [Date] {
        guard let from = promptSwitchFrom(p) else { return [] }
        return SwitchTimes.chips(from: from, to: now, calendar: calendar)
    }

    func lastEndedActivity(before now: Date) -> Activity? {
        storedActivities(on: now).filter { $0.kind != .away && $0.end <= now }.max { $0.end < $1.end }
    }

    private func promptSwitchFrom(_ p: PromptState) -> Date? {
        switch p.kind {
        case .whatNow: return p.switchFrom
        case .center, .stillOnIt: return data.live.tracker.running?.lastAnswer
        case .welcomeBack: return trackerRuntime.lastAway?.end
        case .eventAsk, .todoDue: return nil
        }
    }
}
