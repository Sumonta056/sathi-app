import Foundation

package struct TrackerPromptActions {
    package var start: @MainActor (ActivityDraft, Date?) -> Void = { _, _ in }
    package var skip: @MainActor (Date?) -> Void = { _ in }
    package var stillOn: @MainActor (Int?) -> Void = { _ in }
    package var stillOnLate: @MainActor () -> Void = {}
    package var done: @MainActor () -> Void = {}
    package var continueLast: @MainActor (Date?) -> Void = { _ in }
    package var backToLast: @MainActor () -> Void = {}
    package var iWasHere: @MainActor () -> Void = {}
    package var pickPlace: @MainActor (AwayPlace) -> Void = { _ in }
    package var pickPlaceName: @MainActor (String) -> Void = { _ in }
    package var addPlace: @MainActor (String) -> Void = { _ in }
    package var notAttending: @MainActor (String) -> Void = { _ in }
    package var answerEvent: @MainActor (Bool) -> Void = { _ in }
    package var pickEventCategory: @MainActor (String) -> Void = { _ in }
    package var close: @MainActor () -> Void = {}

    package init() {}
}
