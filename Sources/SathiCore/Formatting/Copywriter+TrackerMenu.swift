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

    package static func trackerQuietUntilMenu(_ time: Date, calendar: Calendar) -> String {
        "Quiet until " + trackerClock(time, calendar: calendar)
    }
}
