import Foundation

struct TodoRuntime {
    var stale = true
    var token = 0
    var loadedSince: Date?
    var loadedRevision: Int?
    var refreshTask: Task<Void, Never>?
}
