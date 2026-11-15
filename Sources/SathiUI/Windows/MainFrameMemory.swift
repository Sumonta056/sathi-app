import AppKit
import SathiCore

struct MainFrameMemory {
    var name = StorageKeys.mainWindowFrame

    func frame() -> CGRect? {
        let probe = NSWindow(contentRect: .zero, styleMask: [.titled, .resizable], backing: .buffered, defer: true)
        probe.isReleasedWhenClosed = false
        return probe.setFrameUsingName(name, force: true) ? probe.frame : nil
    }

    func save(_ window: NSWindow) {
        window.saveFrame(usingName: name)
    }

    func forget() {
        NSWindow.removeFrame(usingName: name)
    }
}
