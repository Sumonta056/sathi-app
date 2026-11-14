import Foundation
import SathiCore

@MainActor
package final class FakeCalendarChangeSource: CalendarChangeSource {
    package private(set) var starts = 0
    package private(set) var stops = 0
    private var listener: (@MainActor () -> Void)?

    package init() {}

    package var isListening: Bool { listener != nil }

    package func start(_ onChange: @escaping @MainActor () -> Void) {
        listener = onChange
        starts += 1
    }

    package func stop() {
        listener = nil
        stops += 1
    }

    package func fire() { listener?() }
}
