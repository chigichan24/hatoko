import KanaKanjiConverterModuleWithDefaultDictionary

enum JapaneseInputState {
    case composing
    case converting(candidates: [Candidate], selectedIndex: Int)
}
