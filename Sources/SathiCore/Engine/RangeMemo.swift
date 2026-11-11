import Foundation

@MainActor
package final class RangeMemo<Request: Equatable, Value> {
    private var inputs: RangeInputs<Request>?
    private var value: Value?

    package init() {}

    package func value(_ request: Request, range: StatsRange, engine: Engine, build: (Engine, Request) -> Value) -> Value {
        let now = engine.rangeInputs(request, range: range)
        if let value, now == inputs { return value }
        let built = build(engine, request)
        inputs = now
        value = built
        return built
    }
}

struct RangeInputs<Request: Equatable>: Equatable {
    let request: Request
    let data: Persisted
    let stores: Int
    let minute: Date?
}

extension Engine {
    func rangeInputs<Request: Equatable>(_ request: Request, range: StatsRange) -> RangeInputs<Request> {
        let n = clock.now
        let minute = Date(timeIntervalSinceReferenceDate: (n.timeIntervalSinceReferenceDate / Timing.minute).rounded(.down) * Timing.minute)
        return RangeInputs(request: request, data: data, stores: storeRevision, minute: range.interval.end > n ? minute : nil)
    }
}
