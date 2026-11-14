import EventKit
import Foundation
import SathiCore

@MainActor
package final class EventKitCalendarChangeSource: CalendarChangeSource {
    private let center: NotificationCenter
    private var token: NSObjectProtocol?

    package init(center: NotificationCenter = .default) {
        self.center = center
    }

    package func start(_ onChange: @escaping @MainActor () -> Void) {
        stop()
        token = center.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { onChange() }
        }
    }

    package func stop() {
        guard let token else { return }
        center.removeObserver(token)
        self.token = nil
    }
}
