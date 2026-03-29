import KanaKanjiConverterModuleWithDefaultDictionary

/// Wraps KanaKanjiConverter for use in HatokoInputController.
///
/// Not marked Sendable because KanaKanjiConverter is not thread-safe.
/// This service is only accessed from HatokoInputController's main-thread callbacks.
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
