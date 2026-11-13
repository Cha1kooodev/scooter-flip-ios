import AppKit

// Иконка 1024×1024 для Scooter Flip.
// Использование: swift make-icon.swift путь/icon-1024.png

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let full = NSRect(x: 0, y: 0, width: size, height: size)
NSColor(calibratedRed: 0.043, green: 0.055, blue: 0.075, alpha: 1).setFill()
full.fill()

// жёлтая скруглённая плитка
let plate = NSBezierPath(roundedRect: full.insetBy(dx: 130, dy: 130), xRadius: 210, yRadius: 210)
NSColor(calibratedRed: 1.0, green: 0.831, blue: 0.0, alpha: 1).setFill()
plate.fill()

// силуэт самоката
var drewSymbol = false
if let symbol = NSImage(systemSymbolName: "scooter", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: 470, weight: .bold)
    if let tinted = symbol.withSymbolConfiguration(config) {
        let tintedImage = NSImage(size: tinted.size)
        tintedImage.lockFocus()
        tinted.draw(in: NSRect(origin: .zero, size: tinted.size))
        NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1).set()
        NSRect(origin: .zero, size: tinted.size).fill(using: .sourceAtop)
        tintedImage.unlockFocus()

        let target = NSSize(width: 560, height: 560 * tinted.size.height / max(tinted.size.width, 1))
        tintedImage.draw(in: NSRect(x: (size - target.width) / 2,
                                    y: (size - target.height) / 2,
                                    width: target.width,
                                    height: target.height))
        drewSymbol = true
    }
}

if !drewSymbol {
    let letter = NSAttributedString(string: "S", attributes: [
        .font: NSFont.systemFont(ofSize: 560, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1)
    ])
    let letterSize = letter.size()
    letter.draw(at: NSPoint(x: (size - letterSize.width) / 2,
                            y: (size - letterSize.height) / 2))
}

// знак рубля в углу
let rub = NSAttributedString(string: "₽", attributes: [
    .font: NSFont.systemFont(ofSize: 190, weight: .heavy),
    .foregroundColor: NSColor(calibratedRed: 0.043, green: 0.055, blue: 0.075, alpha: 1)
])
let rubSize = rub.size()
rub.draw(at: NSPoint(x: 210, y: size - rubSize.height - 190))

image.unlockFocus()

// Рендерим ровно 1024×1024, иначе на Retina получится 2048.
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 1024, pixelsHigh: 1024,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}

try png.write(to: URL(fileURLWithPath: out))
print("ok: \(out)")
