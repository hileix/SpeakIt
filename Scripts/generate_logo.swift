import AppKit

struct OutputImage {
    let filename: String
    let size: CGFloat
}

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let appIconURL = rootURL.appendingPathComponent("AuralAI/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let appLogoURL = rootURL.appendingPathComponent("AuralAI/Assets.xcassets/AppLogo.imageset", isDirectory: true)

let appIcons: [OutputImage] = [
    .init(filename: "icon_16x16.png", size: 16),
    .init(filename: "icon_16x16@2x.png", size: 32),
    .init(filename: "icon_32x32.png", size: 32),
    .init(filename: "icon_32x32@2x.png", size: 64),
    .init(filename: "icon_128x128.png", size: 128),
    .init(filename: "icon_128x128@2x.png", size: 256),
    .init(filename: "icon_256x256.png", size: 256),
    .init(filename: "icon_256x256@2x.png", size: 512),
    .init(filename: "icon_512x512.png", size: 512),
    .init(filename: "icon_512x512@2x.png", size: 1024)
]

let logos: [OutputImage] = [
    .init(filename: "logo_256.png", size: 256),
    .init(filename: "logo_512.png", size: 512)
]

func drawWaveLine(in rect: NSRect, color: NSColor, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round

    path.move(to: NSPoint(x: rect.minX, y: rect.midY))
    path.curve(
        to: NSPoint(x: rect.minX + rect.width * 0.32, y: rect.midY),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.08, y: rect.minY),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY)
    )
    path.curve(
        to: NSPoint(x: rect.minX + rect.width * 0.64, y: rect.midY),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.43, y: rect.minY),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.54, y: rect.maxY)
    )
    path.curve(
        to: NSPoint(x: rect.maxX, y: rect.midY),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.75, y: rect.minY),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.9, y: rect.maxY)
    )

    color.setStroke()
    path.stroke()
}

func drawSpeechBubble(in rect: NSRect, color: NSColor) {
    let bubble = NSBezierPath(roundedRect: rect, xRadius: rect.height * 0.32, yRadius: rect.height * 0.32)
    color.setFill()
    bubble.fill()

    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.04))
    tail.line(to: NSPoint(x: rect.minX + rect.width * 0.14, y: rect.minY - rect.height * 0.16))
    tail.line(to: NSPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.10))
    tail.close()
    tail.fill()
}

func renderLogo(size: CGFloat, includeShadow: Bool) -> NSBitmapImageRep {
    let pixelSize = Int(size.rounded())
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Unable to create bitmap")
    }

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Unable to create graphics context")
    }
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let inset = size * 0.05

    if includeShadow {
        context.setShadow(
            offset: CGSize(width: 0, height: -size * 0.02),
            blur: size * 0.05,
            color: NSColor(calibratedWhite: 0, alpha: 0.10).cgColor
        )
    }

    let backgroundRect = canvas.insetBy(dx: inset, dy: inset)
    let background = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.97, alpha: 1),
        NSColor(calibratedRed: 0.13, green: 0.42, blue: 0.92, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -90)
    context.setShadow(offset: .zero, blur: 0, color: nil)

    let rim = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    rim.lineWidth = max(1, size * 0.006)
    rim.stroke()

    let bubbleRect = NSRect(x: size * 0.18, y: size * 0.30, width: size * 0.64, height: size * 0.42)
    drawSpeechBubble(in: bubbleRect, color: .white)

    let waveRect = NSRect(x: size * 0.29, y: size * 0.43, width: size * 0.34, height: size * 0.08)
    drawWaveLine(
        in: waveRect,
        color: NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.94, alpha: 1),
        lineWidth: max(1.4, size * 0.024)
    )

    graphicsContext.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateLogo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }

    try pngData.write(to: url)
}

try fileManager.createDirectory(at: appLogoURL, withIntermediateDirectories: true)

for icon in appIcons {
    let bitmap = renderLogo(size: icon.size, includeShadow: icon.size >= 64)
    try writePNG(bitmap: bitmap, to: appIconURL.appendingPathComponent(icon.filename))
}

for logo in logos {
    let bitmap = renderLogo(size: logo.size, includeShadow: false)
    try writePNG(bitmap: bitmap, to: appLogoURL.appendingPathComponent(logo.filename))
}

print("Generated \(appIcons.count + logos.count) logo assets.")
