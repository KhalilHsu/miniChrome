#!/usr/bin/env swift

import AppKit
import Foundation

enum AssetKind {
    case app
    case menuBar
}

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let outputRoot = cwd.appendingPathComponent(".build/brand-assets", isDirectory: true)
let extensionIconRoot = cwd.appendingPathComponent("../../extension/chrome/icons", isDirectory: true).standardizedFileURL

try fm.createDirectory(at: outputRoot, withIntermediateDirectories: true)

try renderAsset(
    kind: .app,
    outputName: "AppIcon",
    outputRoot: outputRoot,
    sizes: [16, 32, 128, 256, 512]
)

try renderAsset(
    kind: .menuBar,
    outputName: "MenuBarIcon",
    outputRoot: outputRoot,
    sizes: [16, 32, 128, 256, 512]
)

try renderExtensionIcons(outputRoot: extensionIconRoot)

print("Brand assets written to \(outputRoot.path)")
print("Extension icons written to \(extensionIconRoot.path)")

func renderAsset(kind: AssetKind, outputName: String, outputRoot: URL, sizes: [Int]) throws {
    let iconsetURL = outputRoot.appendingPathComponent("\(outputName).iconset", isDirectory: true)
    if fm.fileExists(atPath: iconsetURL.path) {
        try fm.removeItem(at: iconsetURL)
    }
    try fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

    for size in sizes {
        let baseName = "icon_\(size)x\(size)"
        let image = try pngData(from: renderIcon(kind: kind, size: CGFloat(size)))
        try image.write(to: iconsetURL.appendingPathComponent("\(baseName).png"))

        let retinaSize = size * 2
        let retinaPNG = try pngData(from: renderIcon(kind: kind, size: CGFloat(retinaSize)))
        try retinaPNG.write(to: iconsetURL.appendingPathComponent("\(baseName)@2x.png"))
    }
}

func renderExtensionIcons(outputRoot: URL) throws {
    if fm.fileExists(atPath: outputRoot.path) {
        try fm.removeItem(at: outputRoot)
    }
    try fm.createDirectory(at: outputRoot, withIntermediateDirectories: true)

    for size in [16, 32, 48, 128] {
        let png = try pngData(from: renderIcon(kind: .app, size: CGFloat(size)))
        try png.write(to: outputRoot.appendingPathComponent("icon_\(size).png"))
    }
}

func renderIcon(kind: AssetKind, size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        return image
    }

    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let canvas = CGRect(origin: .zero, size: CGSize(width: size, height: size))

    if kind == .app {
        drawBackground(in: context, rect: canvas.insetBy(dx: size * 0.06, dy: size * 0.06), kind: kind)
        drawAppSymbol(in: context, rect: canvas.insetBy(dx: size * 0.10, dy: size * 0.10))
    } else if kind == .menuBar {
        drawMenuBarIcon(in: context, size: size)
    } else {
        drawBackground(in: context, rect: canvas.insetBy(dx: size * 0.06, dy: size * 0.06), kind: kind)
        drawBrowserWindow(in: context,
                          rect: canvas.insetBy(dx: size * 0.09, dy: size * 0.09),
                          stroke: NSColor(calibratedWhite: 0.98, alpha: 1.0),
                          fill: NSColor(calibratedWhite: 1.0, alpha: 0.06),
                          lineWidth: max(2.0, size * 0.045),
                          accent: NSColor(calibratedRed: 0.20, green: 0.72, blue: 0.78, alpha: 1.0),
                          extensionMode: true)
    }

    return image
}

func drawAppSymbol(in context: CGContext, rect: CGRect) {
    let main = CGRect(x: rect.minX + rect.width * 0.05,
                      y: rect.minY + rect.height * 0.20,
                      width: rect.width * 0.70,
                      height: rect.height * 0.52)
    let mainShell = NSBezierPath(roundedRect: main, xRadius: main.width * 0.13, yRadius: main.height * 0.13)
    NSColor(calibratedWhite: 1.0, alpha: 0.92).setStroke()
    mainShell.lineWidth = max(1.2, rect.width * 0.022)
    mainShell.stroke()

    let titleBar = NSBezierPath(roundedRect: CGRect(x: main.minX + main.width * 0.05,
                                                    y: main.maxY - main.height * 0.22,
                                                    width: main.width - main.width * 0.10,
                                                    height: main.height * 0.12),
                                xRadius: main.height * 0.05,
                                yRadius: main.height * 0.05)
    NSColor(calibratedWhite: 1.0, alpha: 0.10).setFill()
    titleBar.fill()

    let mini = CGRect(x: rect.minX + rect.width * 0.48,
                      y: rect.minY + rect.height * 0.14,
                      width: rect.width * 0.34,
                      height: rect.height * 0.28)
    let miniShell = NSBezierPath(roundedRect: mini, xRadius: mini.width * 0.16, yRadius: mini.height * 0.16)
    NSColor(calibratedRed: 0.18, green: 0.72, blue: 0.78, alpha: 1.0).setFill()
    miniShell.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.86).setStroke()
    miniShell.lineWidth = max(1.0, rect.width * 0.018)
    miniShell.stroke()

    let arrow = NSBezierPath()
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.lineWidth = max(1.0, rect.width * 0.016)
    let start = CGPoint(x: main.minX + main.width * 0.33, y: main.minY + main.height * 0.38)
    let bend = CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.50)
    let end = CGPoint(x: mini.minX + mini.width * 0.66, y: mini.maxY - mini.height * 0.28)
    arrow.move(to: start)
    arrow.line(to: bend)
    arrow.line(to: end)
    NSColor(calibratedWhite: 1.0, alpha: 0.94).setStroke()
    arrow.stroke()

    let head = NSBezierPath()
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.lineWidth = arrow.lineWidth
    head.move(to: CGPoint(x: end.x - rect.width * 0.05, y: end.y))
    head.line(to: end)
    head.line(to: CGPoint(x: end.x, y: end.y - rect.width * 0.05))
    head.stroke()

    let dot = NSBezierPath(ovalIn: CGRect(x: mini.maxX - mini.width * 0.24,
                                          y: mini.minY + mini.height * 0.16,
                                          width: mini.width * 0.12,
                                          height: mini.width * 0.12))
    NSColor(calibratedRed: 0.42, green: 0.86, blue: 0.62, alpha: 1.0).setFill()
    dot.fill()
}

func drawMenuBarIcon(in context: CGContext, size: CGFloat) {
    let stroke = NSColor.labelColor
    let frameRect = CGRect(x: size * 0.17, y: size * 0.20, width: size * 0.66, height: size * 0.54)
    let frame = NSBezierPath(roundedRect: frameRect, xRadius: size * 0.11, yRadius: size * 0.11)
    stroke.setStroke()
    frame.lineWidth = max(1.6, size * 0.07)
    frame.stroke()

    let titleBar = NSBezierPath(roundedRect: CGRect(x: frameRect.minX + size * 0.04,
                                                    y: frameRect.maxY - size * 0.14,
                                                    width: frameRect.width - size * 0.08,
                                                    height: size * 0.07),
                                xRadius: size * 0.03,
                                yRadius: size * 0.03)
    stroke.withAlphaComponent(0.16).setFill()
    titleBar.fill()

    let arrow = NSBezierPath()
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.lineWidth = max(1.8, size * 0.11)
    arrow.move(to: CGPoint(x: frameRect.minX + size * 0.16, y: frameRect.minY + size * 0.14))
    arrow.line(to: CGPoint(x: frameRect.maxX - size * 0.13, y: frameRect.maxY - size * 0.11))
    stroke.setStroke()
    arrow.stroke()

    let head = NSBezierPath()
    let tip = CGPoint(x: frameRect.maxX - size * 0.13, y: frameRect.maxY - size * 0.11)
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.lineWidth = arrow.lineWidth
    head.move(to: CGPoint(x: tip.x - size * 0.09, y: tip.y))
    head.line(to: tip)
    head.line(to: CGPoint(x: tip.x, y: tip.y - size * 0.09))
    head.stroke()

    let dot = NSBezierPath(ovalIn: CGRect(x: frameRect.maxX - size * 0.19,
                                          y: frameRect.minY + size * 0.06,
                                          width: size * 0.07,
                                          height: size * 0.07))
    NSColor(calibratedRed: 0.20, green: 0.72, blue: 0.78, alpha: 1.0).setFill()
    dot.fill()
}

func drawBackground(in context: CGContext, rect: CGRect, kind: AssetKind) {
    let background = NSBezierPath(roundedRect: rect,
                                  xRadius: rect.width * 0.22,
                                  yRadius: rect.width * 0.22)
    let fillColor: NSColor = kind == .app
        ? NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
        : NSColor(calibratedRed: 0.18, green: 0.44, blue: 0.58, alpha: 1.0)
    fillColor.setFill()
    background.fill()

    let ringInset = rect.width * 0.06
    let ring = NSBezierPath(roundedRect: rect.insetBy(dx: ringInset, dy: ringInset),
                            xRadius: rect.width * 0.17,
                            yRadius: rect.width * 0.17)
    NSColor(calibratedWhite: 1.0, alpha: 0.06).setStroke()
    ring.lineWidth = max(1.0, rect.width * 0.02)
    ring.stroke()

    let highlight = NSBezierPath(roundedRect: CGRect(x: rect.minX + rect.width * 0.16,
                                                     y: rect.minY + rect.height * 0.18,
                                                     width: rect.width * 0.52,
                                                     height: rect.height * 0.18),
                                 xRadius: rect.width * 0.09,
                                 yRadius: rect.height * 0.09)
    NSColor(calibratedWhite: 1.0, alpha: 0.05).setFill()
    highlight.fill()
}

func drawBrowserWindow(in context: CGContext,
                       rect: CGRect,
                       stroke: NSColor,
                       fill: NSColor,
                       lineWidth: CGFloat,
                       accent: NSColor,
                       extensionMode: Bool) {
    let shellRect = rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02)
    let shell = NSBezierPath(roundedRect: shellRect, xRadius: shellRect.width * 0.18, yRadius: shellRect.height * 0.18)
    fill.setFill()
    shell.fill()
    stroke.setStroke()
    shell.lineWidth = lineWidth
    shell.stroke()

    let titleBarHeight = shellRect.height * 0.22
    let titleBar = NSBezierPath(roundedRect: CGRect(x: shellRect.minX + shellRect.width * 0.08,
                                                    y: shellRect.maxY - titleBarHeight - shellRect.height * 0.06,
                                                    width: shellRect.width * 0.84,
                                                    height: titleBarHeight),
                                xRadius: titleBarHeight * 0.35,
                                yRadius: titleBarHeight * 0.35)
    stroke.withAlphaComponent(extensionMode ? 0.12 : 0.13).setFill()
    titleBar.fill()

    let dotSize = shellRect.width * 0.055
    let dotY = shellRect.maxY - titleBarHeight * 0.63 - shellRect.height * 0.02
    let dotSpacing = dotSize * 1.4
    let dotXs = [shellRect.minX + shellRect.width * 0.12,
                 shellRect.minX + shellRect.width * 0.12 + dotSpacing,
                 shellRect.minX + shellRect.width * 0.12 + dotSpacing * 2.0]
    let colors: [NSColor] = [
        NSColor(calibratedRed: 0.96, green: 0.34, blue: 0.36, alpha: 1.0),
        NSColor(calibratedRed: 0.96, green: 0.75, blue: 0.28, alpha: 1.0),
        NSColor(calibratedRed: 0.37, green: 0.84, blue: 0.58, alpha: 1.0)
    ]
    for (index, x) in dotXs.enumerated() {
        let dotRect = CGRect(x: x, y: dotY, width: dotSize, height: dotSize)
        colors[index].setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    let contentRect = CGRect(x: shellRect.minX + shellRect.width * 0.12,
                             y: shellRect.minY + shellRect.height * 0.14,
                             width: shellRect.width * 0.62,
                             height: shellRect.height * 0.32)
    let content = NSBezierPath(roundedRect: contentRect, xRadius: contentRect.height * 0.3, yRadius: contentRect.height * 0.3)
    stroke.withAlphaComponent(extensionMode ? 0.14 : 0.18).setFill()
    content.fill()

    let arrowPath = NSBezierPath()
    arrowPath.lineCapStyle = .round
    arrowPath.lineJoinStyle = .round
    arrowPath.lineWidth = max(2.0, shellRect.width * 0.10)
    let start = CGPoint(x: shellRect.minX + shellRect.width * 0.26, y: shellRect.minY + shellRect.height * 0.30)
    let mid = CGPoint(x: shellRect.minX + shellRect.width * 0.50, y: shellRect.minY + shellRect.height * 0.53)
    let end = CGPoint(x: shellRect.maxX - shellRect.width * 0.18, y: shellRect.maxY - shellRect.height * 0.22)
    arrowPath.move(to: start)
    arrowPath.line(to: mid)
    arrowPath.line(to: end)
    stroke.setStroke()
    arrowPath.stroke()

    let head = NSBezierPath()
    let headSize = shellRect.width * 0.10
    head.move(to: CGPoint(x: end.x - headSize * 0.85, y: end.y))
    head.line(to: end)
    head.line(to: CGPoint(x: end.x, y: end.y - headSize * 0.85))
    head.lineWidth = arrowPath.lineWidth
    head.stroke()

    if !extensionMode {
        let accentDot = NSBezierPath(ovalIn: CGRect(x: shellRect.maxX - shellRect.width * 0.24,
                                                    y: shellRect.minY + shellRect.height * 0.12,
                                                    width: shellRect.width * 0.08,
                                                    height: shellRect.width * 0.08))
        accent.setFill()
        accentDot.fill()
    }
}

func pngData(from image: NSImage) throws -> Data {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "BrandAssets", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    return data
}
