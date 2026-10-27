import AppKit
import SathiCore

package struct WorkspaceLinkOpener: LinkOpener {
    package init() {}

    package func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
