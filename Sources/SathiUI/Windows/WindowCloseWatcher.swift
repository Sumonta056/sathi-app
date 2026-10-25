import AppKit

@MainActor
final class WindowCloseWatcher: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}

    func windowWillClose(_: Notification) {
        onClose()
    }
}
