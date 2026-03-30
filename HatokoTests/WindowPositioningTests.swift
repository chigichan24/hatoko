import Cocoa
@testable import Hatoko
import Testing

@Suite
struct WindowPositioningTests {

    private let screenFrame = NSRect(x: 0, y: 0, width: 1920, height: 1080)

    @Test
    func windowPositionedBelowRightOfCursor() {
        let cursorRect = NSRect(x: 500, y: 500, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect, screenFrame: screenFrame)

        #expect(origin.x >= cursorRect.maxX)
        #expect(origin.y + windowSize.height <= cursorRect.minY)
    }

    @Test
    func windowFlipsAboveWhenNoSpaceBelow() {
        let cursorRect = NSRect(x: 500, y: 100, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect, screenFrame: screenFrame)

        #expect(origin.y >= cursorRect.maxY)
    }

    @Test
    func windowClampedToRightEdge() {
        let cursorRect = NSRect(x: 1850, y: 500, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect, screenFrame: screenFrame)

        #expect(origin.x + windowSize.width <= screenFrame.maxX)
        #expect(origin.x >= screenFrame.minX)
    }

    @Test
    func windowClampedToLeftEdge() {
        let cursorRect = NSRect(x: -100, y: 500, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect, screenFrame: screenFrame)

        #expect(origin.x >= screenFrame.minX)
    }

    @Test
    func windowClampedOnBothAxes() {
        let cursorRect = NSRect(x: 1850, y: 50, width: 1, height: 20)
        let windowSize = NSSize(width: 320, height: 200)
        let origin = WindowPositioning.origin(for: windowSize, cursorRect: cursorRect, screenFrame: screenFrame)

        #expect(origin.x >= screenFrame.minX)
        #expect(origin.x + windowSize.width <= screenFrame.maxX)
        #expect(origin.y >= screenFrame.minY)
        #expect(origin.y + windowSize.height <= screenFrame.maxY)
    }
}
