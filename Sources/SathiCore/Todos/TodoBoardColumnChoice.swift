package enum TodoBoardColumnChoice: String, Codable, CaseIterable, Sendable {
    case auto, two, three, four

    package var count: Int? {
        switch self {
        case .auto: nil
        case .two: 2
        case .three: 3
        case .four: 4
        }
    }
}
