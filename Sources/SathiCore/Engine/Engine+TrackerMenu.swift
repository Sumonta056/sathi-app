import Foundation

extension Engine {
    package var trackerNextPopup: Date? {
        let n = clock.now
        let t = data.live.tracker
        guard trackerPrefs.isOn, t.prompt == nil, t.awaySince == nil else { return nil }
        let next: Date? = if let r = t.running {
            max(r.askAt, r.quietUntil ?? r.askAt)
        } else {
            trackerRuntime.whatNowAt ?? trackerHours.nextStart(after: n)
        }
        return next.flatMap { $0 > n ? $0 : nil }
    }
}
