import Cocoa

enum WindowPositioning {

    private static let cursorGap: CGFloat = 4

    /// Calculates the origin for a popup window positioned near the input cursor.
    ///
    /// The window is placed with its top-left corner at the bottom-right of the
    /// cursor rect, with a small gap. If the window would extend beyond the
    /// screen edges, it is clamped to remain fully visible.
    static func origin(for windowSize: NSSize, cursorRect: NSRect) -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(cursorRect.origin) }
            ?? NSScreen.main ?? NSScreen.screens[0]
        let visibleFrame = screen.visibleFrame

        var x = cursorRect.maxX + cursorGap
        var y = cursorRect.minY - cursorGap - windowSize.height

        if y < visibleFrame.minY {
            y = cursorRect.maxY + cursorGap
        }

        if y + windowSize.height > visibleFrame.maxY {
            y = visibleFrame.maxY - windowSize.height
        }

        if x + windowSize.width > visibleFrame.maxX {
            x = visibleFrame.maxX - windowSize.width
        }

        if x < visibleFrame.minX {
            x = visibleFrame.minX
        }

        return NSPoint(x: x, y: y)
    }
}
