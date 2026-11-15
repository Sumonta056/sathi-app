import AppKit
import SathiCore

struct MainFrameMemory {
    var name = StorageKeys.mainWindowFrame

    func frame(loadingInto window: NSWindow) -> CGRect? {
        window.setFrameUsingName(name, force: true) ? window.frame : nil
    }

    func save(_ window: NSWindow) {
        window.saveFrame(usingName: name)
    }

    func forget() {
        NSWindow.removeFrame(usingName: name)
    }
}
