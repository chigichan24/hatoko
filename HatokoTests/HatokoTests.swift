import Testing

@Suite
struct HatokoTests {

    @Test
    func inputModeInitialization() {
        let mode: InputMode = .japanese
        #expect(mode == .japanese)
    }
}
