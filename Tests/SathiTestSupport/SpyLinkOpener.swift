import Foundation
import SathiCore

package final class SpyLinkOpener: LinkOpener, @unchecked Sendable {
    package private(set) var opened: [URL] = []

    package init() {}

    package func open(_ url: URL) { opened.append(url) }
}
