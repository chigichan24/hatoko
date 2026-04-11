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
        let result = converter.requestCandidates(composingText, options: options)
        if result.mainResults.isEmpty, options.zenzaiMode != .off {
            var fallbackOptions = options
            fallbackOptions.zenzaiMode = .off
            return converter.requestCandidates(composingText, options: fallbackOptions)
        }
        return result
    }

    func stopComposition() {
        converter.stopComposition()
    }
}
