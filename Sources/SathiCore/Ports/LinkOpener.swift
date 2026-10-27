import Foundation

package protocol LinkOpener: Sendable {
    func open(_ url: URL)
}
