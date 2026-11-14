import SathiCore

final class ActivityMergeCheckMemo {
    private var key: (ids: Set<ActivityID>, rows: [Activity], held: Set<ActivityID>)?
    private var check: ManualMergeCheck?

    func value(
        _ ids: Set<ActivityID>, rows: [Activity], held: Set<ActivityID>, make: (Set<ActivityID>) -> ManualMergeCheck
    ) -> ManualMergeCheck {
        if let key, let check, key.ids == ids, key.rows == rows, key.held == held { return check }
        let fresh = make(ids)
        key = (ids, rows, held)
        check = fresh
        return fresh
    }
}
