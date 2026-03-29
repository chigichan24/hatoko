import KanaKanjiConverterModuleWithDefaultDictionary

final class ConversionService {

    private let converter: KanaKanjiConverter

    init() {
        self.converter = KanaKanjiConverter.withDefaultDictionary()
    }

    func requestCandidates(
        composingText: ComposingText,
        options: ConvertRequestOptions
    ) -> ConversionResult {
        converter.requestCandidates(composingText, options: options)
    }

    func stopComposition() {
        converter.stopComposition()
    }
}
