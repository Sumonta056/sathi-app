import Foundation

extension Copywriter {
    package static let trackerSpaceKeyName = "Space"
    package static let trackerNamedKeys: [UInt32: String] = [
        Limits.spaceKeyCode: trackerSpaceKeyName,
        Limits.returnKeyCode: "Return", Limits.tabKeyCode: "Tab", Limits.deleteKeyCode: "Delete",
        Limits.leftKeyCode: "←", Limits.rightKeyCode: "→", Limits.downKeyCode: "↓", Limits.upKeyCode: "↑"
    ]
    package static let trackerLogActivity = "Log activity"
    package static let trackerMenuDone = "Done"

    package static func trackerSince(_ start: Date, calendar: Calendar) -> String {
        "since " + trackerClock(start, calendar: calendar)
    }

    package static let trackerSwitchActivity = "Switch activity"
    package static let trackerNotTracking = "Not tracking now"

    package static func trackerSinceFor(_ start: Date, now: Date, calendar: Calendar) -> String {
        let since = trackerSince(start, calendar: calendar)
        guard now.timeIntervalSince(start) >= Timing.minute else { return since }
        return since + " · " + trackerDuration(now.timeIntervalSince(start))
    }

    package static func trackerNextAsk(_ time: Date, calendar: Calendar) -> String {
        "Next ask " + trackerClock(time, calendar: calendar)
    }

    package static func trackerQuietUntilMenu(_ time: Date, calendar: Calendar) -> String {
        "Quiet until " + trackerClock(time, calendar: calendar)
    }
}
