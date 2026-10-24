import Foundation

extension Set {
    package func togglingKeepingOne(_ item: Element) -> Set {
        guard contains(item) else { return union([item]) }
        return count > 1 ? subtracting([item]) : self
    }
}
