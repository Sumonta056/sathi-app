import Foundation

package protocol Clock {
    var now: Date { get }
}

package struct SystemClock: Clock {
    package init() {}
    package var now: Date { Date() }
}
