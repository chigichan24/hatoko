import Cocoa
@testable import Hatoko
import Testing

@Suite
struct WindowPositioningTests {

    @Test
    func windowPositionedBelowRightOfCursor() {
        let cursorRect = NSRect(x: 500, y: 500, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect)

        #expect(origin.x >= cursorRect.maxX)
        #expect(origin.y + windowSize.height <= cursorRect.minY)
    }

    @Test
    func windowFlipsAboveWhenNoSpaceBelow() {
        let cursorRect = NSRect(x: 500, y: 100, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect)

        #expect(origin.y >= cursorRect.maxY)
    }
}
