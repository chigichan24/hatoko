import KanaKanjiConverterModuleWithDefaultDictionary

enum JapaneseInputState {
    case composing
    case converting(candidates: [Candidate], selectedIndex: Int)

    var isConverting: Bool {
        if case .converting = self { return true }
        return false
    }

    var selectedCandidate: Candidate? {
        guard case .converting(let candidates, let index) = self else { return nil }
        guard candidates.indices.contains(index) else { return nil }
        return candidates[index]
    }

    func cycled(reverse: Bool) -> JapaneseInputState {
        guard case .converting(let candidates, let index) = self else { return self }
        guard !candidates.isEmpty else { return self }
        let count = candidates.count
        let next = reverse ? (index - 1 + count) % count : (index + 1) % count
        return .converting(candidates: candidates, selectedIndex: next)
    }
}
