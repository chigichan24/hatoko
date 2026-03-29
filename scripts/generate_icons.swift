#!/usr/bin/env swift

import AppKit

// MARK: - Configuration

let pink = NSColor(srgbRed: 0.95, green: 0.40, blue: 0.50, alpha: 1.0)
let white = NSColor.white

struct IconSpec {
    let filename: String
    let glyph: String
}

let icons: [IconSpec] = [
    IconSpec(filename: "en.tiff", glyph: "A"),
    IconSpec(filename: "main.tiff", glyph: "\u{3042}"),  // あ
]

struct Resolution {
    let size: Int
    let dpi: CGFloat
}

let resolutions: [Resolution] = [
    Resolution(size: 16, dpi: 72),   // @1x
    Resolution(size: 32, dpi: 144),  // @2x
]

// MARK: - Drawing

func createRepresentation(glyph: String, resolution: Resolution) -> NSBitmapImageRep {
    let size = resolution.size
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    // Set DPI via size property: size in points = pixels / (dpi / 72)
    let pointSize = CGFloat(size) * 72.0 / resolution.dpi
    rep.size = NSSize(width: pointSize, height: pointSize)

    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    // Draw in point coordinates (not pixel coordinates)
    // The @2x bitmap rep automatically renders at higher resolution
    let drawSize = pointSize
    let rect = NSRect(x: 0, y: 0, width: drawSize, height: drawSize)

    // Draw rounded rectangle background
    let cornerRadius = drawSize * 3.0 / 16.0
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    pink.setFill()
    path.fill()

    // Draw glyph text
    let fontSize = drawSize * 0.7
    let font: NSFont
    if glyph == "A" {
        font = NSFont.boldSystemFont(ofSize: fontSize)
    } else {
        // Use Hiragino Sans for Japanese characters
        font = NSFont(name: "HiraginoSans-W6", size: fontSize)
            ?? NSFont.boldSystemFont(ofSize: fontSize)
    }

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: white,
    ]

    let attrString = NSAttributedString(string: glyph, attributes: attributes)
    let textSize = attrString.size()

    let textX = (drawSize - textSize.width) / 2.0
    let textY = (drawSize - textSize.height) / 2.0
    attrString.draw(at: NSPoint(x: textX, y: textY))

    NSGraphicsContext.restoreGraphicsState()

    return rep
}

func generateIcon(spec: IconSpec, outputDir: String) {
    let image = NSImage(size: NSSize(width: 16, height: 16))

    for resolution in resolutions {
        let rep = createRepresentation(glyph: spec.glyph, resolution: resolution)
        image.addRepresentation(rep)
    }

    guard let tiffData = image.tiffRepresentation else {
        print("Error: Failed to generate TIFF data for \(spec.filename)")
        exit(1)
    }

    let outputPath = "\(outputDir)/\(spec.filename)"
    let url = URL(fileURLWithPath: outputPath)

    do {
        try tiffData.write(to: url)
        print("Generated: \(outputPath)")
    } catch {
        print("Error writing \(outputPath): \(error)")
        exit(1)
    }
}

// MARK: - Main

let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let outputDir = scriptPath.appendingPathComponent("Hatoko/Resources").path

// Verify output directory exists
let fileManager = FileManager.default
guard fileManager.fileExists(atPath: outputDir) else {
    print("Error: Output directory does not exist: \(outputDir)")
    exit(1)
}

print("Output directory: \(outputDir)")

for spec in icons {
    generateIcon(spec: spec, outputDir: outputDir)
}

print("Done! Generated \(icons.count) icon files.")
