import AppKit

@MainActor
enum MenuBarWindow {
    static func close() {
        NSApp?.keyWindow?.close()
    }
}
