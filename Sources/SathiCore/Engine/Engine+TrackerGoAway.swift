import Foundation

extension Engine {
    package func goAway(place: AwayPlace, name: String?) {
        guard trackerPrefs.isOn else { return }
        trackerRuntime.whatNowAt = nil
        clearTrackerPrompt()
        data.live.tracker.awayPlan = AwayPlan(place: place, name: name)
        beginAway(at: clock.now, cause: .chosen)
    }
}
