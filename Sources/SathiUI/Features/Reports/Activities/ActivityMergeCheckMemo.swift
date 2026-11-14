import SathiCore

final class ActivityMergeCheckMemo {
    private var key: (ids: Set<ActivityID>, rows: [Activity])?
    private var check: ManualMergeCheck?

    func value(_ ids: Set<ActivityID>, rows: [Activity], make: (Set<ActivityID>) -> ManualMergeCheck) -> ManualMergeCheck {
        if let key, let check, key.ids == ids, key.rows == rows { return check }
        let fresh = make(ids)
        key = (ids, rows)
        check = fresh
        return fresh
    }
}
