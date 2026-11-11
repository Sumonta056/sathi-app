import Foundation

package enum RangeExport: Equatable, Sendable {
    case saved(URL)
    case empty
    case failed

    package var url: URL? {
        if case let .saved(url) = self { return url }
        return nil
    }
}
