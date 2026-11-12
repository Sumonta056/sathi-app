import Foundation

extension Engine {
    package func goAway(place: AwayPlace, name: String?) {
        guard trackerPrefs.isOn else { return }
        let n = clock.now
        if data.live.tracker.awaySince != nil { returnFromAway(at: n, welcomes: false) }
        trackerRuntime.whatNowAt = nil
        clearTrackerPrompt()
        data.live.tracker.awayPlan = AwayPlan(place: place, name: name)
        beginAway(at: n, cause: .chosen)
    }
}
