import Foundation

package struct DashboardScore: Equatable, Sendable {
    package var met: Int
    package var possible: Int
    package var changeText: String
    package var isUp: Bool

    package init(met: Int, possible: Int, changeText: String, isUp: Bool) {
        self.met = met
        self.possible = possible
        self.changeText = changeText
        self.isUp = isUp
    }
}
