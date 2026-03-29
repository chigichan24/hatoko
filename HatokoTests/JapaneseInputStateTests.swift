@testable import Hatoko
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@Suite
struct JapaneseInputStateTests {

    private static func makeCandidate(text: String) -> Candidate {
        Candidate(text: text, value: 0, composingCount: .inputCount(text.count), lastMid: 0, data: [])
    }

    private static let sampleCandidates = [
        makeCandidate(text: "今日は雨"),
        makeCandidate(text: "京は雨"),
        makeCandidate(text: "きょうはあめ"),
    ]

    @Test
    func composingIsNotConverting() {
        let state = JapaneseInputState.composing
        #expect(!state.isConverting)
        #expect(state.selectedCandidate == nil)
    }

    @Test
    func convertingIsConverting() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 0)
        #expect(state.isConverting)
    }

    @Test
    func selectedCandidateReturnsCorrectCandidate() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 1)
        #expect(state.selectedCandidate?.text == "京は雨")
    }

    @Test
    func selectedCandidateReturnsNilForOutOfBoundsIndex() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 5)
        #expect(state.selectedCandidate == nil)
    }

    @Test
    func selectedCandidateReturnsNilForEmptyCandidates() {
        let state = JapaneseInputState.converting(candidates: [], selectedIndex: 0)
        #expect(state.selectedCandidate == nil)
    }

    @Test
    func cycleForwardAdvancesIndex() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 0)
        let next = state.cycled(reverse: false)
        #expect(next.selectedCandidate?.text == "京は雨")
    }

    @Test
    func cycleForwardWrapsAround() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 2)
        let next = state.cycled(reverse: false)
        #expect(next.selectedCandidate?.text == "今日は雨")
    }

    @Test
    func cycleReverseWrapsAround() {
        let state = JapaneseInputState.converting(candidates: Self.sampleCandidates, selectedIndex: 0)
        let next = state.cycled(reverse: true)
        #expect(next.selectedCandidate?.text == "きょうはあめ")
    }

    @Test
    func cycledOnComposingReturnsComposing() {
        let state = JapaneseInputState.composing
        let next = state.cycled(reverse: false)
        #expect(!next.isConverting)
    }

    @Test
    func cycledWithEmptyCandidatesReturnsSelf() {
        let state = JapaneseInputState.converting(candidates: [], selectedIndex: 0)
        let next = state.cycled(reverse: false)
        #expect(next.selectedCandidate == nil)
    }
}
