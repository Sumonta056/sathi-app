import Foundation

extension Copywriter {
    package static func todosBadge(_ n: Int) -> String {
        "\(n) due today"
    }

    package static func sidebarBadged(_ title: String, _ badge: String) -> String {
        title + ", " + badge
    }
}
