import CoreGraphics
import Foundation
import ImageIO
import KikoCore
import UniformTypeIdentifiers

/// Offscreen contact sheet, driven through the real Rig with scripted mouse input.
/// This is how the art and the physics get checked without touching the live cursor.
enum Sheet {
    private struct Scene {
        let name: String
        let run: (Rig, CGRect) -> Pose
    }

    private static let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private static let dt = 1.0 / 60

    private static func hold(_ rig: Rig, at p: CGPoint, seconds: Double, buttons: Int = 0, kind: CursorKind = .arrow) -> Pose {
        var pose = Pose()
        for _ in 0..<Int(seconds / dt) {
            pose = rig.step(RigInput(dt: dt, mouse: p, buttons: buttons, kind: kind, screen: screen))
        }
        return pose
    }

    private static func sweep(_ rig: Rig, from a: CGPoint, velocity v: CGPoint, seconds: Double, kind: CursorKind = .arrow) -> Pose {
        var pose = Pose()
        for i in 0..<Int(seconds / dt) {
            let t = Double(i) * dt
            let p = CGPoint(x: a.x + v.x * t, y: a.y + v.y * t)
            pose = rig.step(RigInput(dt: dt, mouse: p, kind: kind, screen: screen))
        }
        return pose
    }

    private static let centre = CGPoint(x: 700, y: 480)

    /// Moments only the newer characters have anything to show for.
    private static let extraScenes: [Scene] = [
        Scene(name: "after a click") { rig, _ in
            _ = hold(rig, at: centre, seconds: 0.5)
            _ = hold(rig, at: centre, seconds: 0.08, buttons: 1)
            return hold(rig, at: centre, seconds: 0.2)
        },
        Scene(name: "text cursor, moving") { rig, _ in
            _ = hold(rig, at: CGPoint(x: 200, y: 400), seconds: 0.5, kind: .other)
            return sweep(rig, from: CGPoint(x: 200, y: 400), velocity: CGPoint(x: 900, y: 300), seconds: 0.3, kind: .other)
        },
    ]

    private static func scenes(for avatar: Avatar) -> [Scene] {
        avatar == .kiko ? scenes : scenes + extraScenes
    }

    private static let scenes: [Scene] = [
        Scene(name: "rest") { rig, _ in hold(rig, at: centre, seconds: 1.0) },
        Scene(name: "flying right") { rig, _ in
            _ = hold(rig, at: CGPoint(x: 200, y: 400), seconds: 0.5)
            return sweep(rig, from: CGPoint(x: 200, y: 400), velocity: CGPoint(x: 1500, y: 150), seconds: 0.35)
        },
        Scene(name: "flying left") { rig, _ in
            _ = hold(rig, at: CGPoint(x: 1100, y: 400), seconds: 0.5)
            return sweep(rig, from: CGPoint(x: 1100, y: 400), velocity: CGPoint(x: -1500, y: -100), seconds: 0.35)
        },
        Scene(name: "click") { rig, _ in
            _ = hold(rig, at: centre, seconds: 0.5)
            return hold(rig, at: centre, seconds: 0.09, buttons: 1)
        },
        Scene(name: "drag") { rig, _ in
            _ = hold(rig, at: centre, seconds: 0.5)
            return hold(rig, at: centre, seconds: 0.8, buttons: 1)
        },
        Scene(name: "over a link") { rig, _ in hold(rig, at: centre, seconds: 1.0, kind: .link) },
        Scene(name: "text cursor") { rig, _ in hold(rig, at: centre, seconds: 1.0, kind: .other) },
        Scene(name: "asleep") { rig, _ in hold(rig, at: centre, seconds: 29) },
        Scene(name: "dizzy") { rig, _ in
            var x = 700.0
            var dir = 1.0
            var pose = Pose()
            for i in 0..<70 {
                if i % 9 == 0 { dir = -dir }
                x += dir * 34
                pose = rig.step(RigInput(dt: dt, mouse: CGPoint(x: x, y: 480), screen: screen))
            }
            return hold(rig, at: CGPoint(x: x, y: 480), seconds: 0.5).expression == .dizzy
                ? hold(rig, at: CGPoint(x: x, y: 480), seconds: 0.1) : pose
        },
        Scene(name: "right edge") { rig, s in hold(rig, at: CGPoint(x: s.maxX - 8, y: 400), seconds: 1.0) },
        Scene(name: "bottom edge") { rig, s in hold(rig, at: CGPoint(x: 600, y: s.maxY - 8), seconds: 1.0) },
        Scene(name: "top edge") { rig, s in hold(rig, at: CGPoint(x: 600, y: s.minY + 3), seconds: 1.0) },
    ]

    /// Stands in for the real I-beam on the sheet.
    private static func ibeam() -> CursorImage {
        let ctx = CGContext(data: nil, width: 18, height: 32, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.fill(CGRect(x: 8, y: 4, width: 2, height: 24))
        ctx.fill(CGRect(x: 4, y: 2, width: 10, height: 2))
        ctx.fill(CGRect(x: 4, y: 28, width: 10, height: 2))
        return CursorImage(image: ctx.makeImage()!, size: CGSize(width: 9, height: 16), hotSpot: CGPoint(x: 4.5, y: 8))
    }

    static func render(to url: URL, avatar: Avatar = .kiko) {
        let scenes = scenes(for: avatar)
        let columns = 6
        let cellW = 250, cellH = 250, rowsPerBg = Int(ceil(Double(scenes.count) / Double(columns)))
        let backgrounds: [CGColor] = [
            CGColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1),
            CGColor(srgbRed: 0.11, green: 0.12, blue: 0.15, alpha: 1),
        ]
        let trueSizeStrip = 150
        let scale = 2
        let width = cellW * columns * scale
        let height = (cellH * rowsPerBg * backgrounds.count + trueSizeStrip) * scale
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))

        let poses = scenes.map { scene -> Pose in scene.run(Rig(avatar: avatar), screen) }

        for (b, bg) in backgrounds.enumerated() {
            let top = CGFloat(b * rowsPerBg * cellH)
            ctx.setFillColor(bg)
            ctx.fill(CGRect(x: 0, y: top, width: CGFloat(cellW * columns), height: CGFloat(cellH * rowsPerBg)))
            for (i, pose) in poses.enumerated() {
                let x = CGFloat(i % columns * cellW), y = top + CGFloat(i / columns * cellH)
                ctx.saveGState()
                ctx.clip(to: CGRect(x: x, y: y, width: CGFloat(cellW), height: CGFloat(cellH)))
                // Zoomed 1.6x so that details can be judged.
                ctx.translateBy(x: x + CGFloat(cellW) / 2 - pose.body.x * 1.6, y: y + CGFloat(cellH) / 2 - (pose.body.y - 6) * 1.6)
                ctx.scaleBy(x: 1.6, y: 1.6)
                AvatarRenderer.draw(pose, in: ctx, cursor: scenes[i].name.hasPrefix("text cursor") ? ibeam() : nil)
                // Red cross on the hotspot, so a finger that misses it is obvious.
                ctx.setStrokeColor(CGColor(srgbRed: 1, green: 0, blue: 0.2, alpha: 0.9))
                ctx.setLineWidth(0.4)
                ctx.move(to: CGPoint(x: -3, y: 0)); ctx.addLine(to: CGPoint(x: 3, y: 0))
                ctx.move(to: CGPoint(x: 0, y: -3)); ctx.addLine(to: CGPoint(x: 0, y: 3))
                ctx.strokePath()
                ctx.restoreGState()
            }
        }

        // Bottom strip: true on-screen sizes against light and dark.
        let stripTop = CGFloat(rowsPerBg * cellH * backgrounds.count)
        let stripW = CGFloat(cellW * columns)
        ctx.setFillColor(backgrounds[0])
        ctx.fill(CGRect(x: 0, y: stripTop, width: stripW / 2, height: CGFloat(trueSizeStrip)))
        ctx.setFillColor(backgrounds[1])
        ctx.fill(CGRect(x: stripW / 2, y: stripTop, width: stripW / 2, height: CGFloat(trueSizeStrip)))
        for half in 0..<2 {
            for (i, s) in [CGFloat(0.65), 0.85, 1.1].enumerated() {
                ctx.saveGState()
                ctx.translateBy(x: CGFloat(half) * stripW / 2 + 60 + CGFloat(i) * 220, y: stripTop + 30)
                ctx.scaleBy(x: s, y: s)
                AvatarRenderer.draw(poses[0], in: ctx)
                ctx.restoreGState()
            }
        }

        write(ctx.makeImage()!, to: url)
    }

    /// Close-ups of a few scenes, for judging line work.
    static func portrait(to url: URL, avatar: Avatar = .kiko) {
        let picks = avatar == .kiko ? ["rest", "click", "flying left"] : ["rest", "click", "over a link", "asleep"]
        let zoom: CGFloat = 5
        let cell = 760
        let ctx = CGContext(data: nil, width: cell * picks.count, height: cell, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(cell))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(CGColor(srgbRed: 0.8, green: 0.85, blue: 0.9, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: cell * picks.count, height: cell))
        for (i, name) in picks.enumerated() {
            guard let scene = scenes.first(where: { $0.name == name }) else { continue }
            let pose = scene.run(Rig(avatar: avatar), screen)
            ctx.saveGState()
            ctx.clip(to: CGRect(x: i * cell, y: 0, width: cell, height: cell))
            ctx.translateBy(x: CGFloat(i * cell) + CGFloat(cell) / 2 - pose.body.x * zoom + 40,
                            y: CGFloat(cell) / 2 - (pose.body.y - 8) * zoom)
            ctx.scaleBy(x: zoom, y: zoom)
            AvatarRenderer.draw(pose, in: ctx)
            ctx.restoreGState()
        }
        write(ctx.makeImage()!, to: url)
    }

    /// Everyone side by side: the same moments, on light and on dark.
    static func lineup(to url: URL) {
        let picks = ["rest", "click", "over a link", "asleep"]
        let cellW = 230, cellH = 220, scale = 2
        let backgrounds: [CGColor] = [
            CGColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1),
            CGColor(srgbRed: 0.11, green: 0.12, blue: 0.15, alpha: 1),
        ]
        let rows = Avatar.allCases.count
        let width = cellW * picks.count * backgrounds.count * scale
        let height = cellH * rows * scale
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
        for (b, bg) in backgrounds.enumerated() {
            let left = CGFloat(b * picks.count * cellW)
            ctx.setFillColor(bg)
            ctx.fill(CGRect(x: left, y: 0, width: CGFloat(picks.count * cellW), height: CGFloat(height)))
            for (r, avatar) in Avatar.allCases.enumerated() {
                for (c, name) in picks.enumerated() {
                    guard let scene = scenes.first(where: { $0.name == name }) else { continue }
                    let pose = scene.run(Rig(avatar: avatar), screen)
                    let x = left + CGFloat(c * cellW), y = CGFloat(r * cellH)
                    ctx.saveGState()
                    ctx.clip(to: CGRect(x: x, y: y, width: CGFloat(cellW), height: CGFloat(cellH)))
                    ctx.translateBy(x: x + CGFloat(cellW) / 2 - pose.body.x * 1.55, y: y + CGFloat(cellH) / 2 - (pose.body.y - 8) * 1.55)
                    ctx.scaleBy(x: 1.55, y: 1.55)
                    AvatarRenderer.draw(pose, in: ctx)
                    ctx.restoreGState()
                }
            }
        }
        write(ctx.makeImage()!, to: url)
    }

    /// Times the drawing alone, into a bitmap the size of the live window's backing store.
    static func bench(avatar: Avatar = .kiko) {
        let side = 384
        let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: CGFloat(side) / 2, y: CGFloat(side) / 2)
        ctx.scaleBy(x: 2 * 0.85, y: -2 * 0.85)
        let pose = hold(Rig(avatar: avatar), at: centre, seconds: 1)
        let frames = 2000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<frames {
            ctx.saveGState()
            ctx.clear(CGRect(x: -200, y: -200, width: 400, height: 400))
            AvatarRenderer.draw(pose, in: ctx)
            ctx.restoreGState()
        }
        let ms = (CFAbsoluteTimeGetCurrent() - start) / Double(frames) * 1000
        print(String(format: "\(avatar.rawValue) draw: %.2f ms per frame, %.1f%% of a core at 30 fps, %.1f%% at 60 fps", ms, ms * 3, ms * 6))
    }

    /// The 1024px app icon: Kiko's head on a rounded tile.
    static func icon(to url: URL) {
        let size = 1024
        let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(size))
        ctx.scaleBy(x: 1, y: -1)

        // Apple's icon grid: an 824px tile centred in the 1024px canvas.
        let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil))
        ctx.clip()
        let colors = [CGColor(srgbRed: 0.33, green: 0.38, blue: 0.80, alpha: 1),
                      CGColor(srgbRed: 0.18, green: 0.20, blue: 0.47, alpha: 1)] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])

        var pose = Rig().step(RigInput(dt: dt, mouse: centre, screen: screen))
        pose.look = CGPoint(x: -0.5, y: -0.3)
        pose.turn = 0
        // Point up and to the left, the way the app does.
        pose.fingerTip = CGPoint(x: pose.body.x - 34, y: pose.body.y - 25)
        let zoom: CGFloat = 8.4
        ctx.translateBy(x: 524 - pose.body.x * zoom, y: 625 - pose.body.y * zoom)
        ctx.scaleBy(x: zoom, y: zoom)
        AvatarRenderer.draw(pose, in: ctx)
        ctx.restoreGState()

        write(ctx.makeImage()!, to: url)
    }

    static func write(_ image: CGImage, to url: URL) {
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}
