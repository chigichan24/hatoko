import Cocoa

enum WindowPositioning {

    private static let cursorGap: CGFloat = 4

    /// Calculates the origin for a popup window positioned near the input cursor.
    ///
    /// The window is placed with its top-left corner at the bottom-right of the
    /// cursor rect, with a small gap. If the window would extend beyond the
    /// screen edges, it is clamped to remain fully visible.
    static func origin(for windowSize: NSSize, cursorRect: NSRect) -> NSPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorRect.origin) })
            ?? NSScreen.main
            ?? NSScreen.screens.first else {
            return NSPoint(x: cursorRect.maxX + cursorGap,
                           y: cursorRect.minY - cursorGap - windowSize.height)
        }
        return origin(for: windowSize, cursorRect: cursorRect, screenFrame: screen.visibleFrame)
    }

    /// Calculates origin with an explicit screen frame. Exposed for testing.
    static func origin(for windowSize: NSSize, cursorRect: NSRect, screenFrame: NSRect) -> NSPoint {
        var x = cursorRect.maxX + cursorGap
        var y = cursorRect.minY - cursorGap - windowSize.height

        if y < screenFrame.minY {
            y = cursorRect.maxY + cursorGap
        }

        if y + windowSize.height > screenFrame.maxY {
            y = screenFrame.maxY - windowSize.height
        }

        if x + windowSize.width > screenFrame.maxX {
            x = screenFrame.maxX - windowSize.width
        }

        if x < screenFrame.minX {
            x = screenFrame.minX
        }

        return NSPoint(x: x, y: y)
    }
}
