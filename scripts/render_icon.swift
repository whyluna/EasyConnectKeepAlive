import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? FileManager.default.currentDirectoryPath + "/AppIcon-1024.png"
let size = 1024

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create icon drawing context")
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let iconRect = NSRect(x: 42, y: 42, width: 940, height: 940)
let iconShape = NSBezierPath(roundedRect: iconRect, xRadius: 214, yRadius: 214)

NSGraphicsContext.saveGraphicsState()
let iconShadow = NSShadow()
iconShadow.shadowColor = color(0.01, 0.07, 0.20, 0.42)
iconShadow.shadowBlurRadius = 30
iconShadow.shadowOffset = NSSize(width: 0, height: -16)
iconShadow.set()
color(0.02, 0.18, 0.56).setFill()
iconShape.fill()
NSGraphicsContext.restoreGraphicsState()

let backgroundGradient = NSGradient(colors: [
    color(0.025, 0.13, 0.48),
    color(0.02, 0.40, 0.82),
    color(0.00, 0.78, 0.94)
])!
backgroundGradient.draw(in: iconShape, angle: 90)

NSGraphicsContext.saveGraphicsState()
iconShape.addClip()
let highlight = NSBezierPath(ovalIn: NSRect(x: 135, y: 650, width: 750, height: 390))
color(0.35, 0.76, 1.00, 0.13).setFill()
highlight.fill()
let glow = NSBezierPath(ovalIn: NSRect(x: 215, y: 105, width: 630, height: 360))
color(0.00, 0.92, 1.00, 0.12).setFill()
glow.fill()
NSGraphicsContext.restoreGraphicsState()

color(0.46, 0.88, 1.00, 0.45).setStroke()
iconShape.lineWidth = 5
iconShape.stroke()

let shield = NSBezierPath()
shield.move(to: NSPoint(x: 512, y: 823))
shield.curve(
    to: NSPoint(x: 788, y: 686),
    controlPoint1: NSPoint(x: 635, y: 745),
    controlPoint2: NSPoint(x: 710, y: 704)
)
shield.curve(
    to: NSPoint(x: 740, y: 376),
    controlPoint1: NSPoint(x: 790, y: 545),
    controlPoint2: NSPoint(x: 782, y: 445)
)
shield.curve(
    to: NSPoint(x: 512, y: 198),
    controlPoint1: NSPoint(x: 684, y: 291),
    controlPoint2: NSPoint(x: 586, y: 225)
)
shield.curve(
    to: NSPoint(x: 284, y: 376),
    controlPoint1: NSPoint(x: 438, y: 225),
    controlPoint2: NSPoint(x: 340, y: 291)
)
shield.curve(
    to: NSPoint(x: 236, y: 686),
    controlPoint1: NSPoint(x: 242, y: 445),
    controlPoint2: NSPoint(x: 234, y: 545)
)
shield.curve(
    to: NSPoint(x: 512, y: 823),
    controlPoint1: NSPoint(x: 314, y: 704),
    controlPoint2: NSPoint(x: 389, y: 745)
)
shield.close()

NSGraphicsContext.saveGraphicsState()
let shieldShadow = NSShadow()
shieldShadow.shadowColor = color(0.01, 0.08, 0.27, 0.40)
shieldShadow.shadowBlurRadius = 26
shieldShadow.shadowOffset = NSSize(width: 0, height: -18)
shieldShadow.set()
color(0.94, 0.98, 1.00).setFill()
shield.fill()
NSGraphicsContext.restoreGraphicsState()

let shieldGradient = NSGradient(colors: [
    color(1.00, 1.00, 1.00),
    color(0.90, 0.96, 1.00)
])!
shieldGradient.draw(in: shield, angle: 90)
color(0.73, 0.87, 0.98, 0.75).setStroke()
shield.lineWidth = 6
shield.stroke()

let pulse = NSBezierPath()
pulse.move(to: NSPoint(x: 316, y: 500))
pulse.line(to: NSPoint(x: 403, y: 500))
pulse.line(to: NSPoint(x: 452, y: 552))
pulse.line(to: NSPoint(x: 500, y: 420))
pulse.line(to: NSPoint(x: 557, y: 690))
pulse.line(to: NSPoint(x: 612, y: 347))
pulse.line(to: NSPoint(x: 665, y: 552))
pulse.line(to: NSPoint(x: 706, y: 500))
pulse.line(to: NSPoint(x: 758, y: 500))
pulse.lineWidth = 42
pulse.lineCapStyle = .round
pulse.lineJoinStyle = .round

NSGraphicsContext.saveGraphicsState()
let pulseShadow = NSShadow()
pulseShadow.shadowColor = color(0.00, 0.42, 0.78, 0.32)
pulseShadow.shadowBlurRadius = 12
pulseShadow.shadowOffset = NSSize(width: 0, height: -4)
pulseShadow.set()
color(0.00, 0.69, 0.91).setStroke()
pulse.stroke()
NSGraphicsContext.restoreGraphicsState()

let pulseHighlight = pulse.copy() as! NSBezierPath
pulseHighlight.lineWidth = 16
color(0.10, 0.89, 1.00, 0.88).setStroke()
pulseHighlight.stroke()

let dotCenter = NSPoint(x: 758, y: 500)
NSGraphicsContext.saveGraphicsState()
let dotGlow = NSShadow()
dotGlow.shadowColor = color(0.00, 0.95, 0.43, 0.55)
dotGlow.shadowBlurRadius = 25
dotGlow.shadowOffset = .zero
dotGlow.set()
color(1, 1, 1, 0.96).setFill()
NSBezierPath(ovalIn: NSRect(x: dotCenter.x - 50, y: dotCenter.y - 50, width: 100, height: 100)).fill()
NSGraphicsContext.restoreGraphicsState()

let dot = NSBezierPath(ovalIn: NSRect(x: dotCenter.x - 36, y: dotCenter.y - 36, width: 72, height: 72))
let dotGradient = NSGradient(colors: [
    color(0.16, 1.00, 0.48),
    color(0.00, 0.73, 0.30)
])!
dotGradient.draw(in: dot, angle: 90)
color(0.00, 0.52, 0.22).setStroke()
dot.lineWidth = 4
dot.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon PNG")
}
try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
print(outputPath)
