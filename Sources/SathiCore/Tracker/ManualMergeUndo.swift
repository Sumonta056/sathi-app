import Foundation

package struct ManualMergeUndo: Equatable, Sendable {
    package var merged: Activity
    package var before: [Activity]
    package var keptEventRow: Activity?
    package var deletedEventRows: [Activity]
    package var until: Date
}
