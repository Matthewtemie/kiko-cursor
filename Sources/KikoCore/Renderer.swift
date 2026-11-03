import CoreGraphics

private func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

private enum Ink {
    static let line = rgb(0x2A1A3E)
    static let halo = rgb(0xFFFFFF)
    static let skin = rgb(0xFFE6D3)
    static let skinShade = rgb(0xF7C6AE)
    static let hair = rgb(0xF58B3D)
    static let hairDark = rgb(0xD4652A)
    static let hairLight = rgb(0xFFC27A)
    static let cream = rgb(0xFFF3E0)
    static let earInner = rgb(0xFFCDB8)
    static let earTip = rgb(0x5A2E2A)
    static let hoodie = rgb(0x5261C4)
    static let hoodieDark = rgb(0x3D4A9C)
    static let scarf = rgb(0xE8373D)
    static let scarfDark = rgb(0xB4222C)
    static let leg = rgb(0x2F2B55)
    static let shoe = rgb(0xFFFFFF)
    static let blush = rgb(0xFF7E8B, 0.55)
    static let mouth = rgb(0x8E2B3B)
    static let tongue = rgb(0xFF8A94)
    static let spark = rgb(0xFFD84D)
    static let white = rgb(0xFFFFFF)
    static let shadowEye = rgb(0x2A1A3E, 0.18)
    static let iris = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [rgb(0x0B4F63), rgb(0x1E9AA6), rgb(0x6DF0D6)] as CFArray,
                                 locations: [0, 0.55, 1])!
}

private extension CGMutablePath {
    func m(_ x: CGFloat, _ y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
    func l(_ x: CGFloat, _ y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
    func q(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
    }
    func z() { closeSubpath() }
}

private func path(_ build: (CGMutablePath) -> Void) -> CGPath {
    let p = CGMutablePath()
    build(p)
    return p
}

/// Fixed outlines, built once. Head shapes are centred on the head; everything is in points.
private enum Shape {
    static let face = path {
        $0.m(-16, -3); $0.c(-16, -14, -8, -18, 0, -18); $0.c(8, -18, 16, -14, 16, -3)
        $0.c(16, 5, 8, 12, 0, 14.5); $0.c(-8, 12, -16, 5, -16, -3); $0.z()
    }
    static let hairBack = path {
        $0.m(-19, -6); $0.c(-20, -19, -10, -25, 0, -25); $0.c(10, -25, 20, -19, 19, -6)
        $0.c(20, 2, 21, 9, 18, 15); $0.l(14.5, 10.5); $0.l(11, 15.5); $0.l(7, 10)
        $0.l(-7, 10); $0.l(-11, 15.5); $0.l(-14.5, 10.5); $0.l(-18, 15)
        $0.c(-21, 9, -20, 2, -19, -6); $0.z()
    }
    static let bangs = path {
        $0.m(-17.5, 1); $0.c(-19.5, -12, -11, -22.5, 0, -22.5); $0.c(11, -22.5, 19.5, -12, 17.5, 1)
        $0.q(15.8, -4.5, 13.8, -8.5); $0.q(13, -5, 10.5, -3.2)
        $0.q(9.8, -7, 7.5, -10.5); $0.q(6.5, -6.5, 3.5, -3.8)
        $0.q(2.6, -8, 0.5, -11.5); $0.q(-1, -7, -4.6, -3.8)
        $0.q(-5, -8, -7, -10.5); $0.q(-8, -6.5, -11, -3.2)
        $0.q(-11.6, -5.8, -13.8, -8.5); $0.q(-15.8, -4.5, -17.5, 1); $0.z()
    }
    static let lockL = path {
        $0.m(-17.5, -8); $0.q(-20.8, 5, -16.5, 13.5); $0.q(-14.2, 7, -13.4, -6); $0.z()
    }
    static let lockR = path {
        $0.m(17.5, -8); $0.q(20.8, 5, 16.5, 13.5); $0.q(14.2, 7, 13.4, -6); $0.z()
    }
    static let ear = path {
        $0.m(-6.5, 1.5); $0.q(-7.2, -10, -1.6, -17.5); $0.q(0, -19.2, 1.6, -17.5); $0.q(7.2, -10, 6.5, 1.5); $0.z()
    }
    static let earInner = path {
        $0.m(-3.6, 1); $0.q(-3.9, -7, 0, -12.5); $0.q(3.9, -7, 3.6, 1); $0.z()
    }
    static let torso = path {
        $0.m(-7, -1); $0.c(-10, 4, -10.8, 11, -10.2, 17); $0.q(0, 19.8, 10.2, 17)
        $0.c(10.8, 11, 10, 4, 7, -1); $0.z()
    }
    static let scarfWrap = path {
        $0.m(-9.6, -2.4); $0.q(0, -4.6, 9.6, -2.4); $0.q(11.4, 1, 9.6, 4.2)
        $0.q(0, 6.8, -9.6, 4.2); $0.q(-11.4, 1, -9.6, -2.4); $0.z()
    }
    static let tail = path {
        $0.m(0, -2.5); $0.c(6, -9, 16, -13.5, 24, -8.5); $0.q(30, -4.5, 32, 1)
        $0.q(24, 7.5, 15, 7.5); $0.c(8, 7.5, 3, 5, 0, 2.5); $0.z()
    }
    static let tailTip = path {
        $0.m(21, -14); $0.q(17, -3, 20.5, -1); $0.q(17.5, 2, 19.5, 9); $0.l(36, 9); $0.l(36, -14); $0.z()
    }
    static let spark = path {
        $0.m(0, -1); $0.q(0.14, -0.14, 1, 0); $0.q(0.14, 0.14, 0, 1)
        $0.q(-0.14, 0.14, -1, 0); $0.q(-0.14, -0.14, 0, -1); $0.z()
    }
    static let zee = path { $0.m(-1, -1); $0.l(1, -1); $0.l(-1, 1); $0.l(1, 1) }
    static let lash = path {
        $0.m(-5.3, -2.8); $0.q(-4.8, -6.4, 0, -6.8); $0.q(4.6, -6.6, 5.6, -3.2)
        $0.q(6.8, -2.6, 7.4, -3.8); $0.q(7.2, -1.4, 5.1, -1.8)
        $0.q(4, -5, 0, -5.2); $0.q(-3.8, -5, -5.3, -2.8); $0.z()
    }
}

/// Draws filled, outlined shapes. On the halo pass the same calls lay down a white
/// sticker edge, which is what keeps Kiko readable on dark windows.
private struct Painter {
    let ctx: CGContext
    let halo: Bool
    private let edge: CGFloat = 2.2

    func shape(_ p: CGPath, _ fill: CGColor, line: CGFloat = 1.15) {
        ctx.addPath(p)
        if halo {
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth(line + edge)
            ctx.strokePath()
        } else {
            ctx.setFillColor(fill)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(line)
            ctx.drawPath(using: .fillStroke)
        }
    }

    func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ fill: CGColor, line: CGFloat = 1.15) {
        shape(CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2), transform: nil), fill, line: line)
    }

    /// A round-ended tube: dark outline stroke, then the colour on top.
    func limb(_ a: CGPoint, _ ctrl: CGPoint, _ b: CGPoint, width: CGFloat, _ color: CGColor) {
        let p = CGMutablePath()
        p.move(to: a)
        p.addQuadCurve(to: b, control: ctrl)
        ctx.addPath(p)
        if halo {
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth(width + 2.3 + edge)
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(width + 2.3)
            ctx.strokePath()
            ctx.addPath(p)
            ctx.setStrokeColor(color)
            ctx.setLineWidth(width)
            ctx.strokePath()
        }
    }
}

public enum KikoRenderer {
    /// Draws one frame. The context's origin must be the hotspot, with y pointing down.
    public static func draw(_ pose: Pose, in ctx: CGContext, cursor: CursorImage? = nil) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        for halo in [true, false] {
            let p = Painter(ctx: ctx, halo: halo)
            drawScarfTail(p, pose.scarfB)
            drawScarfTail(p, pose.scarfA)
            inBodySpace(ctx, pose) { drawLowerBody(p, pose) }
            drawPointingArm(p, pose)
            inBodySpace(ctx, pose) { drawHead(p, pose) }
        }
        drawParticles(ctx, pose)

        if let cursor {
            ctx.saveGState()
            ctx.translateBy(x: -cursor.hotSpot.x, y: cursor.size.height - cursor.hotSpot.y)
            ctx.scaleBy(x: 1, y: -1)
            ctx.draw(cursor.image, in: CGRect(origin: .zero, size: cursor.size))
            ctx.restoreGState()
        }
    }

    private static func inBodySpace(_ ctx: CGContext, _ pose: Pose, _ draw: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: pose.body.x, y: pose.body.y + pose.bob)
        ctx.rotate(by: pose.lean)
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        ctx.scaleBy(x: sign * max(abs(pose.facing), 0.14) * (2 - pose.squash), y: pose.squash)
        draw()
        ctx.restoreGState()
    }

    // MARK: Body

    private static func drawScarfTail(_ p: Painter, _ pts: [CGPoint]) {
        guard pts.count > 1 else { return }
        let path = CGMutablePath()
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        var endDir = CGPoint.zero
        for i in pts.indices {
            let a = pts[max(i - 1, 0)]
            let b = pts[min(i + 1, pts.count - 1)]
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(hypot(dx, dy), 0.01)
            let t = CGFloat(i) / CGFloat(pts.count - 1)
            let w = 1.9 + 1.3 * t   // narrow at the knot, flaring toward the end
            left.append(CGPoint(x: pts[i].x - dy / len * w, y: pts[i].y + dx / len * w))
            right.append(CGPoint(x: pts[i].x + dy / len * w, y: pts[i].y - dx / len * w))
            endDir = CGPoint(x: dx / len, y: dy / len)
        }
        path.move(to: left[0])
        for i in 1..<left.count {
            path.addQuadCurve(to: mid(left[i - 1], left[i]), control: left[i - 1])
        }
        path.addLine(to: left[left.count - 1])
        // Swallowtail notch, the classic anime scarf end.
        let end = pts[pts.count - 1]
        path.addLine(to: CGPoint(x: end.x - endDir.x * 2.8, y: end.y - endDir.y * 2.8))
        path.addLine(to: right[right.count - 1])
        for i in stride(from: right.count - 1, to: 0, by: -1) {
            path.addQuadCurve(to: mid(right[i], right[i - 1]), control: right[i])
        }
        path.addLine(to: right[0])
        path.closeSubpath()
        p.shape(path, Ink.scarf)
    }

    private static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func drawLowerBody(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx

        // Tail
        ctx.saveGState()
        ctx.translateBy(x: 6, y: 14)
        ctx.rotate(by: pose.tailAngle)
        p.shape(Shape.tail, Ink.hair)
        if !p.halo {
            ctx.saveGState()
            ctx.addPath(Shape.tail)
            ctx.clip()
            ctx.addPath(Shape.tailTip)
            ctx.setFillColor(Ink.cream)
            ctx.fillPath()
            ctx.restoreGState()
            ctx.addPath(Shape.tail)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.15)
            ctx.strokePath()
        }
        ctx.restoreGState()

        // Legs and shoes
        let swing = pose.legSwing
        for (x, s) in [(CGFloat(-4.3), swing), (CGFloat(4.3), -swing)] {
            let foot = CGPoint(x: x + s * 2.6, y: 23.5 - abs(s) * 0.8)
            p.limb(CGPoint(x: x, y: 16.5), CGPoint(x: x, y: 20), foot, width: 3.8, Ink.leg)
            p.oval(foot.x + (x < 0 ? -0.9 : 0.9), foot.y + 1.2, 3.5, 2.4, Ink.shoe)
        }

        // Free arm, behind the torso
        let freeHand = CGPoint(x: 11.5 + pose.armSwing * 2.5, y: 11.5 - abs(pose.armSwing) * 1.2)
        p.limb(CGPoint(x: 7.5, y: 3.5), CGPoint(x: 10.5, y: 6.5), freeHand, width: 4, Ink.hoodie)
        p.oval(freeHand.x + 0.2, freeHand.y + 1, 2.5, 2.5, Ink.skin, line: 1)

        // Torso
        p.shape(Shape.torso, Ink.hoodie)
        if !p.halo {
            // Cel shade down the side away from the viewer's light.
            ctx.saveGState()
            ctx.addPath(Shape.torso)
            ctx.clip()
            ctx.setFillColor(Ink.hoodieDark)
            ctx.fill(CGRect(x: 5.4, y: -2, width: 7, height: 22))
            ctx.restoreGState()
            ctx.addPath(Shape.torso)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(1.15)
            ctx.strokePath()

            ctx.setStrokeColor(Ink.hoodieDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: 0, y: 5)); ctx.addLine(to: CGPoint(x: 0, y: 11))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: -5.6, y: 13)); ctx.addQuadCurve(to: CGPoint(x: 5.6, y: 13), control: CGPoint(x: 0, y: 10.4))
            ctx.strokePath()
        }

        // Scarf around the neck
        p.shape(Shape.scarfWrap, Ink.scarf)
        if !p.halo {
            ctx.setStrokeColor(Ink.scarfDark)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: -7.8, y: 1.4)); ctx.addQuadCurve(to: CGPoint(x: 7.8, y: 1.4), control: CGPoint(x: 0, y: 3.2))
            ctx.strokePath()
        }
    }

    private static func drawPointingArm(_ p: Painter, _ pose: Pose) {
        let sign: CGFloat = pose.facing < 0 ? -1 : 1
        let lean = pose.lean
        let lx = sign * -7.8, ly: CGFloat = 3.5
        let shoulder = CGPoint(x: pose.body.x + lx * cos(lean) - ly * sin(lean),
                               y: pose.body.y + pose.bob + lx * sin(lean) + ly * cos(lean))
        let tip = pose.fingerTip

        let dx = tip.x - shoulder.x, dy = tip.y - shoulder.y
        let len = max(hypot(dx, dy), 0.01)
        let ux = dx / len, uy = dy / len

        let fingerReach: CGFloat = 7.6 * max(pose.reach, 0.25)
        let hand = CGPoint(x: tip.x - ux * fingerReach, y: tip.y - uy * fingerReach)
        let wrist = CGPoint(x: hand.x - ux * 2.6, y: hand.y - uy * 2.6)

        // The sleeve sags more the less it has to stretch.
        let sag = max(0, 11 - len * 0.14) * sign
        let ctrl = CGPoint(x: (shoulder.x + wrist.x) / 2 + uy * sag * -1, y: (shoulder.y + wrist.y) / 2 + ux * sag)
        p.limb(shoulder, ctrl, wrist, width: 4.2, Ink.hoodie)

        if !p.halo {
            let cuff = CGMutablePath()
            cuff.move(to: CGPoint(x: wrist.x - uy * 2.4, y: wrist.y + ux * 2.4))
            cuff.addLine(to: CGPoint(x: wrist.x + uy * 2.4, y: wrist.y - ux * 2.4))
            p.ctx.addPath(cuff)
            p.ctx.setStrokeColor(Ink.hoodieDark)
            p.ctx.setLineWidth(1.3)
            p.ctx.strokePath()
        }

        // Hand and tapered pointing finger. The outline's outer edge lands exactly on the
        // tip, so the visible point of the finger is where the click goes.
        let line: CGFloat = 1.05
        let halfWidth: CGFloat = 1.75
        let px = -uy, py = ux
        let fingerEnd = CGPoint(x: tip.x - ux * line / 2, y: tip.y - uy * line / 2)
        let base = CGPoint(x: hand.x + ux * 1.2, y: hand.y + uy * 1.2)
        let waist = mid(base, fingerEnd)
        let finger = CGMutablePath()
        finger.move(to: CGPoint(x: base.x + px * halfWidth, y: base.y + py * halfWidth))
        finger.addQuadCurve(to: fingerEnd, control: CGPoint(x: waist.x + px * halfWidth * 0.95, y: waist.y + py * halfWidth * 0.95))
        finger.addQuadCurve(to: CGPoint(x: base.x - px * halfWidth, y: base.y - py * halfWidth),
                            control: CGPoint(x: waist.x - px * halfWidth * 0.95, y: waist.y - py * halfWidth * 0.95))
        finger.closeSubpath()
        p.shape(finger, Ink.skin, line: line)
        p.oval(hand.x, hand.y, 3.3, 3.3, Ink.skin, line: line)
        if !p.halo {
            // Hide the seam where the finger meets the palm.
            let seam = CGMutablePath()
            seam.move(to: CGPoint(x: hand.x + ux * 0.6, y: hand.y + uy * 0.6))
            seam.addLine(to: CGPoint(x: base.x + ux * 1.4, y: base.y + uy * 1.4))
            p.ctx.addPath(seam)
            p.ctx.setStrokeColor(Ink.skin)
            p.ctx.setLineWidth(halfWidth * 1.75)
            p.ctx.strokePath()
        }
    }

    // MARK: Head

    private static func drawHead(_ p: Painter, _ pose: Pose) {
        let ctx = p.ctx
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.translateBy(x: 0, y: -1)
        ctx.rotate(by: pose.headTilt)
        ctx.translateBy(x: 0, y: -14.5)

        let turn = pose.turn * 1.25

        p.shape(Shape.hairBack, Ink.hairDark)

        // Ears sit behind the fringe and slide opposite the face.
        for (x, base, flick) in [(CGFloat(-12), CGFloat(-0.3), -pose.earL), (CGFloat(12), CGFloat(0.3), pose.earR)] {
            ctx.saveGState()
            ctx.translateBy(x: x - turn * 0.5, y: -19.5)
            ctx.rotate(by: base + flick)
            p.shape(Shape.ear, Ink.hair)
            if !p.halo {
                ctx.saveGState()
                ctx.addPath(Shape.ear)
                ctx.clip()
                ctx.setFillColor(Ink.earTip)
                ctx.fill(CGRect(x: -9, y: -21, width: 18, height: 7.2))
                ctx.restoreGState()
                ctx.addPath(Shape.earInner)
                ctx.setFillColor(Ink.earInner)
                ctx.fillPath()
                ctx.addPath(Shape.ear)
                ctx.setStrokeColor(Ink.line)
                ctx.setLineWidth(1.15)
                ctx.strokePath()
            }
            ctx.restoreGState()
        }

        p.shape(Shape.face, Ink.skin)
        if p.halo {
            p.shape(Shape.lockL, Ink.hair)
            p.shape(Shape.lockR, Ink.hair)
            p.shape(Shape.bangs, Ink.hair)
            return
        }

        // Shadow the fringe throws on the forehead.
        ctx.saveGState()
        ctx.addPath(Shape.face)
        ctx.clip()
        ctx.translateBy(x: turn * 0.4, y: 2.1)
        ctx.addPath(Shape.bangs)
        ctx.setFillColor(Ink.skinShade)
        ctx.fillPath()
        ctx.restoreGState()

        // Blush
        for sx in [CGFloat(-1), 1] {
            let rect = CGRect(x: sx * 9.7 + turn - 2.9, y: 8, width: 5.8, height: 2.8)
            ctx.setFillColor(Ink.blush)
            ctx.fillEllipse(in: rect)
        }

        drawEyes(p, pose, turn: turn)
        drawMouth(p, pose, turn: turn)

        // Side locks, then the fringe over their tops and the top of the face.
        p.shape(Shape.lockL, Ink.hair)
        p.shape(Shape.lockR, Ink.hair)
        ctx.saveGState()
        ctx.translateBy(x: turn * 0.4, y: 0)
        p.shape(Shape.bangs, Ink.hair)
        ctx.addPath(hairShine)
        ctx.setStrokeColor(Ink.hairLight)
        ctx.setLineWidth(1.5)
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static let hairShine = path {
        $0.m(-11, -15.5); $0.q(-6, -19.5, -1.5, -19.6)
        $0.m(3.5, -19.4); $0.q(7, -18.8, 9.5, -16.6)
    }

    private static func drawEyes(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        for side in [CGFloat(-1), 1] {
            ctx.saveGState()
            ctx.translateBy(x: side * 6.9 + turn, y: 3.3)

            switch pose.expression {
            case .happy:
                arc(ctx, CGPoint(x: -4.6, y: 1.4), CGPoint(x: 0, y: -5.2), CGPoint(x: 4.6, y: 1.4), width: 1.9)
            case .asleep:
                arc(ctx, CGPoint(x: -4.6, y: -0.6), CGPoint(x: 0, y: 3.6), CGPoint(x: 4.6, y: -0.6), width: 1.8)
            case .dizzy:
                drawSpiral(ctx, flip: side)
            default:
                drawOpenEye(ctx, pose, side: side)
            }
            ctx.restoreGState()

            // Brows
            guard pose.expression == .focused || pose.expression == .surprised else { continue }
            let browY: CGFloat = pose.expression == .focused ? -2.6 : -5.4
            let tilt: CGFloat = pose.expression == .focused ? 1.3 : -0.6
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.9)
            ctx.move(to: CGPoint(x: side * 10 + turn, y: browY - tilt))
            ctx.addLine(to: CGPoint(x: side * 4.4 + turn, y: browY + tilt))
            ctx.strokePath()
        }
    }

    private static func arc(_ ctx: CGContext, _ a: CGPoint, _ c: CGPoint, _ b: CGPoint, width: CGFloat) {
        ctx.move(to: a)
        ctx.addQuadCurve(to: b, control: c)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(width)
        ctx.strokePath()
    }

    private static func drawOpenEye(_ ctx: CGContext, _ pose: Pose, side: CGFloat) {
        let open = max(min(pose.blink, 1), 0)
        if open < 0.2 {
            arc(ctx, CGPoint(x: -4.6, y: 0.6), CGPoint(x: 0, y: 2.6), CGPoint(x: 4.6, y: 0.6), width: 1.7)
            return
        }

        let surprised = pose.expression == .surprised
        let focused = pose.expression == .focused
        let lookX = pose.look.x * 1.3
        let lookY = pose.look.y * 0.9

        ctx.saveGState()
        ctx.translateBy(x: 0, y: 1.4)
        ctx.scaleBy(x: 1, y: open)
        ctx.translateBy(x: 0, y: -1.4)

        let white = CGRect(x: -4.9, y: -5.9, width: 9.8, height: 12)
        ctx.setFillColor(Ink.white)
        ctx.fillEllipse(in: white)

        ctx.saveGState()
        ctx.addEllipse(in: white)
        ctx.clip()

        let rx: CGFloat = surprised ? 2.9 : 4.1
        let ry: CGFloat = surprised ? 3.9 : 5.5
        let irisRect = CGRect(x: lookX - rx, y: 0.4 + lookY - ry, width: rx * 2, height: ry * 2)
        ctx.saveGState()
        ctx.addEllipse(in: irisRect)
        ctx.clip()
        ctx.drawLinearGradient(Ink.iris, start: CGPoint(x: 0, y: irisRect.minY), end: CGPoint(x: 0, y: irisRect.maxY), options: [])
        ctx.restoreGState()

        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.7)
        ctx.strokeEllipse(in: irisRect)

        ctx.setFillColor(Ink.line)
        let prx = rx * 0.5, pry = ry * 0.56
        ctx.fillEllipse(in: CGRect(x: lookX - prx, y: 0.2 + lookY - pry, width: prx * 2, height: pry * 2))

        // Shadow under the upper lid
        ctx.setFillColor(Ink.shadowEye)
        ctx.fill(CGRect(x: -6, y: -6.5, width: 12, height: 3))

        ctx.restoreGState()

        // Highlights stay fixed in the upper left of both eyes, as cel animation does.
        ctx.setFillColor(Ink.white)
        if pose.expression == .excited {
            ctx.saveGState()
            ctx.translateBy(x: lookX - 0.8, y: lookY - 0.8)
            ctx.scaleBy(x: 3.4, y: 3.4)
            ctx.addPath(Shape.spark)
            ctx.fillPath()
            ctx.restoreGState()
        } else {
            let big: CGFloat = surprised ? 1.1 : 1.75
            ctx.fillEllipse(in: CGRect(x: lookX - 1.9 - big, y: lookY - 2.0 - big, width: big * 2, height: big * 2))
            ctx.setFillColor(rgb(0xFFFFFF, 0.8))
            ctx.fillEllipse(in: CGRect(x: lookX + 1.1, y: lookY + 2.2, width: 1.6, height: 1.6))
        }

        // Upper lash, with a flick at the outer corner.
        ctx.saveGState()
        if side > 0 {
            ctx.scaleBy(x: 1, y: 1)
        } else {
            ctx.scaleBy(x: -1, y: 1)
        }
        if focused { ctx.translateBy(x: 0, y: 1.2) }
        ctx.addPath(Shape.lash)
        ctx.setFillColor(Ink.line)
        ctx.fillPath()
        ctx.restoreGState()

        ctx.restoreGState()
    }

    private static func drawSpiral(_ ctx: CGContext, flip: CGFloat) {
        let s = CGMutablePath()
        var first = true
        for i in 0...26 {
            let t = CGFloat(i) / 26
            let a = t * .pi * 4.4 * flip
            let r = 0.5 + t * 4.3
            let pt = CGPoint(x: cos(a) * r, y: sin(a) * r + 0.4)
            if first { s.move(to: pt); first = false } else { s.addLine(to: pt) }
        }
        ctx.addPath(s)
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(1.1)
        ctx.strokePath()
    }

    private static func drawMouth(_ p: Painter, _ pose: Pose, turn: CGFloat) {
        let ctx = p.ctx
        ctx.saveGState()
        ctx.translateBy(x: turn, y: 10.7)
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(Ink.line)
        ctx.setLineWidth(0.95)

        switch pose.expression {
        case .happy, .excited:
            let m = path {
                $0.m(-3.3, -0.9); $0.q(0, -0.1, 3.3, -0.9); $0.q(2.8, 3.5, 0, 3.6); $0.q(-2.8, 3.5, -3.3, -0.9); $0.z()
            }
            ctx.addPath(m)
            ctx.setFillColor(Ink.mouth)
            ctx.fillPath()
            ctx.saveGState()
            ctx.addPath(m)
            ctx.clip()
            ctx.setFillColor(Ink.tongue)
            ctx.fillEllipse(in: CGRect(x: -2.1, y: 1.2, width: 4.2, height: 3.2))
            // A small fang, for the fox.
            let fang = path { $0.m(-2.2, -0.8); $0.l(-0.8, -0.6); $0.l(-1.6, 0.8); $0.z() }
            ctx.addPath(fang)
            ctx.setFillColor(Ink.white)
            ctx.fillPath()
            ctx.restoreGState()
            ctx.addPath(m)
            ctx.strokePath()
        case .surprised:
            let r = CGRect(x: -1.6, y: -1, width: 3.2, height: 3.6)
            ctx.setFillColor(Ink.mouth)
            ctx.fillEllipse(in: r)
            ctx.strokeEllipse(in: r)
        case .focused:
            ctx.move(to: CGPoint(x: -2, y: 0.5)); ctx.addLine(to: CGPoint(x: 2, y: 0.1))
            ctx.strokePath()
        case .asleep:
            ctx.move(to: CGPoint(x: -1.4, y: 0.2))
            ctx.addQuadCurve(to: CGPoint(x: 1.4, y: 0.2), control: CGPoint(x: 0, y: 1.6))
            ctx.strokePath()
        case .dizzy:
            ctx.move(to: CGPoint(x: -3, y: 0.6))
            ctx.addQuadCurve(to: CGPoint(x: -1, y: 0.4), control: CGPoint(x: -2, y: -0.8))
            ctx.addQuadCurve(to: CGPoint(x: 1, y: 0.4), control: CGPoint(x: 0, y: 1.7))
            ctx.addQuadCurve(to: CGPoint(x: 3, y: 0.4), control: CGPoint(x: 2, y: -0.8))
            ctx.strokePath()
        case .neutral:
            // The little cat mouth.
            ctx.move(to: CGPoint(x: -2.7, y: -0.3))
            ctx.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -1.4, y: 1.7))
            ctx.addQuadCurve(to: CGPoint(x: 2.7, y: -0.3), control: CGPoint(x: 1.4, y: 1.7))
            ctx.strokePath()
        }
    }

    // MARK: Particles

    private static func drawParticles(_ ctx: CGContext, _ pose: Pose) {
        for s in pose.sparkles where s.alpha > 0.01 {
            ctx.saveGState()
            ctx.setAlpha(s.alpha)
            ctx.translateBy(x: s.pos.x, y: s.pos.y)
            ctx.rotate(by: s.rot)
            ctx.scaleBy(x: s.size, y: s.size)
            ctx.addPath(Shape.spark)
            ctx.setFillColor(Ink.spark)
            ctx.setStrokeColor(Ink.line)
            ctx.setLineWidth(0.9 / s.size)
            ctx.drawPath(using: .fillStroke)
            ctx.restoreGState()
        }
        for z in pose.zees where z.alpha > 0.01 {
            ctx.saveGState()
            ctx.setAlpha(z.alpha)
            ctx.translateBy(x: z.pos.x, y: z.pos.y)
            ctx.scaleBy(x: z.size, y: z.size)
            ctx.addPath(Shape.zee)
            ctx.setStrokeColor(Ink.halo)
            ctx.setLineWidth(3 / z.size)
            ctx.strokePath()
            ctx.addPath(Shape.zee)
            ctx.setStrokeColor(Ink.hoodie)
            ctx.setLineWidth(1.3 / z.size)
            ctx.strokePath()
            ctx.restoreGState()
        }
    }
}
