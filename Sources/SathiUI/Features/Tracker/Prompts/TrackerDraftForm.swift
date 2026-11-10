import SathiCore
import SwiftUI

@MainActor
final class TrackerDraftForm: ObservableObject {
    @Published var draft: ActivityDraft

    init(_ draft: ActivityDraft) { self.draft = draft }
}
