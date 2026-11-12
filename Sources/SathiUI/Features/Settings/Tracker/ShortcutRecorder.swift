import AppKit
import SathiCore

@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    func start(onCapture: @escaping @MainActor (KeyShortcut) -> Void) {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let code = UInt32(event.keyCode)
            if ShortcutCapture.isCancel(keyCode: code) {
                self?.stop()
            } else if let s = ShortcutCapture.shortcut(keyCode: code, flags: event.modifierFlags, characters: event.charactersIgnoringModifiers) {
                onCapture(s)
                self?.stop()
            }
            return nil
        }
    }

    func stop() {
        isRecording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
