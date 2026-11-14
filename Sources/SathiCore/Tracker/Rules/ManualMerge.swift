import Foundation

package enum ManualMergeBlock: Equatable, Sendable {
    case tooFew, notStored, differentDays, eventRow, buddyRow, timeBlockRow, namedAway, rowBetween, awayUndo
}

package struct ManualMergePlan: Equatable, Sendable {
    package var merged: Activity
    package var rows: [Activity]
    package var removedAway: [Activity]
    package var keptEventRow: Activity?
    package var droppedEventRows: [Activity]
}

package enum ManualMergeCheck: Equatable {
    case ok(ManualMergePlan)
    case blocked(ManualMergeBlock)
}

extension ManualMergeCheck {
    package static func check(_ ids: Set<ActivityID>, dayRows: [Activity], calendar: Calendar) -> ManualMergeCheck {
        guard ids.count >= Limits.manualMergeMinRows else { return .blocked(.tooFew) }
        let selected = dayRows.filter { ids.contains($0.id) }.sorted { $0.start < $1.start }
        guard selected.count == ids.count else { return .blocked(.notStored) }
        guard let day = selected.first?.start,
              selected.allSatisfy({ calendar.isDate($0.start, inSameDayAs: day) }) else { return .blocked(.differentDays) }
        if let reason = selected.lazy.compactMap(Self.reason).first { return .blocked(reason) }
        let work = selected.filter { $0.kind == .work }
        guard work.count >= Limits.manualMergeMinRows, let first = work.first, let end = work.map(\.end).max() else {
            return .blocked(.tooFew)
        }
        let span = DateInterval(start: first.start, end: max(first.start, end))
        var removed = selected.filter { $0.kind == .away }
        for other in dayRows where !ids.contains(other.id) && Self.overlaps(other, span) {
            if other.kind == .away, Self.isUnnamed(other) { removed.append(other); continue }
            return .blocked(Self.reason(other) ?? .rowBetween)
        }
        return .ok(Self.plan(work, removed: removed, end: end))
    }

    private static func plan(_ work: [Activity], removed: [Activity], end: Date) -> ManualMergePlan {
        var merged = work[0]
        merged.end = max(work[0].end, end)
        let withEvent = work.filter(ActivityMerge.hasEvent)
        if let kept = withEvent.first {
            merged.eventID = kept.eventID
            merged.calendarID = kept.calendarID
        }
        return ManualMergePlan(
            merged: merged, rows: work, removedAway: removed.sorted { $0.start < $1.start },
            keptEventRow: withEvent.first, droppedEventRows: Array(withEvent.dropFirst())
        )
    }

    private static func reason(_ row: Activity) -> ManualMergeBlock? {
        switch row.kind {
        case .event: .eventRow
        case .buddy: .buddyRow
        case .timeBlock: .timeBlockRow
        case .away: isUnnamed(row) ? nil : .namedAway
        case .work: row.sourceEventID == nil ? nil : .eventRow
        }
    }

    private static func isUnnamed(_ row: Activity) -> Bool { row.awayPlace == nil && row.awayPlaceName == nil }

    private static func overlaps(_ row: Activity, _ span: DateInterval) -> Bool {
        row.start < span.end && row.end > span.start
    }
}
