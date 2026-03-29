@testable import Hatoko
import Testing

@Suite
struct InputModeTests {

    @Test
    func japaneseIdentifierParsesToJapanese() {
        let mode = InputMode(modeIdentifier: "com.chigichan24.inputmethod.Hatoko.Japanese")
        #expect(mode == .japanese)
    }

    @Test
    func romanIdentifierParsesToRoman() {
        let mode = InputMode(modeIdentifier: "com.chigichan24.inputmethod.Hatoko.Roman")
        #expect(mode == .roman)
    }

    @Test
    func unknownIdentifierDefaultsToJapanese() {
        let mode = InputMode(modeIdentifier: "some.unknown.mode")
        #expect(mode == .japanese)
    }
}
