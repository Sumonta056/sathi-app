import SathiCore

enum CalendarMergePick {
    static func id(of block: CalendarBlock) -> ActivityID? {
        guard case let .activity(activity, running) = block.source, !running else { return nil }
        return activity.id
    }

    static func rows(_ blocks: [CalendarBlock]) -> [Activity] {
        blocks.compactMap {
            if case let .activity(activity, running) = $0.source, !running { activity } else { nil }
        }
    }

    static func pruned(_ selected: Set<ActivityID>, in rows: [Activity]) -> Set<ActivityID> {
        ActivityMergeBar.pruned(selected, in: rows)
    }

    static func toggle(all ids: [ActivityID], in selected: inout Set<ActivityID>) {
        if !ids.isEmpty, ids.allSatisfy(selected.contains) { selected.subtract(ids) } else { selected.formUnion(ids) }
    }

    static func toggle(_ id: ActivityID, in selected: inout Set<ActivityID>) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }
}
