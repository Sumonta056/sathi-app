import Foundation
@testable import SathiUI

@MainActor
final class TodoFinishingGate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var delays: [TimeInterval] = []
    private(set) var writes: [String] = []

    var waiting: Int { waiters.count }

    func wait(_ delay: TimeInterval) async {
        delays.append(delay)
        await withCheckedContinuation { waiters.append($0) }
    }

    func record(_ id: String) {
        writes.append(id)
    }

    func release() {
        let pending = waiters
        waiters = []
        for waiter in pending {
            waiter.resume()
        }
    }

    func settle() async {
        for _ in 0 ..< 200 {
            await Task.yield()
        }
    }

    func finishing() -> TodoFinishing {
        TodoFinishing(wait: { [self] in await wait($0) }, write: { [self] in record($0) })
    }
}

extension TodoFinishing {
    static func idle() -> TodoFinishing {
        TodoFinishing(wait: { _ in try? await Task.sleep(for: .seconds(3600)) }, write: { _ in })
    }
}
