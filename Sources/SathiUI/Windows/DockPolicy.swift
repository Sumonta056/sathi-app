import AppKit

enum DockPolicy {
    static func policy(mainWindowOpen: Bool) -> NSApplication.ActivationPolicy {
        mainWindowOpen ? .regular : .accessory
    }
}
