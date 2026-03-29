enum InputMode: Sendable, Equatable {
    case japanese
    case roman

    init(modeIdentifier: String) {
        if modeIdentifier.hasSuffix("Roman") {
            self = .roman
        } else {
            self = .japanese
        }
    }
}
