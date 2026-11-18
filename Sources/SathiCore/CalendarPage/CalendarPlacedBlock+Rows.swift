import Foundation

extension CalendarPlacedBlock {
    package func row(_ id: String) -> CalendarBlock? {
        ([self] + children + hidden).lazy.flatMap(\.block.rows).first { $0.id == id }
    }
}

extension CalendarBlock {
    package var rows: [CalendarBlock] {
        group?.members ?? [self]
    }

    package var mergeIDs: [ActivityID] {
        rows.compactMap {
            guard case let .activity(a, running) = $0.source, !running else { return nil }
            return a.id
        }
    }
}
