import Foundation

extension Engine {
    package func setTrackerAskEvery(_ minutes: Int) {
        let old = trackerPrefs.askEveryMinutes
        guard minutes != old else { return }
        data.prefs.tracker.askEveryMinutes = minutes
        let n = clock.now.wholeSecond
        if let r = data.live.tracker.running {
            guard r.kind == .work, !trackerIsQuiet else { return }
            data.live.tracker.running?.askAt = AskTime.moved(r, from: old, to: minutes, now: n)
        } else if let w = trackerRuntime.whatNowAt {
            trackerRuntime.whatNowAt = max(n, w.addingTimeInterval(TimeInterval(minutes - old) * Timing.minute))
        }
        requestTick()
    }
}
