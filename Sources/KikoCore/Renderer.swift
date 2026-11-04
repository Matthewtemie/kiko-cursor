import CoreGraphics

public enum AvatarRenderer {
    /// Draws one frame. The context's origin must be the hotspot, with y pointing down.
    public static func draw(_ pose: Pose, in ctx: CGContext, cursor: CursorImage? = nil) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch pose.avatar {
        case .kiko: KikoArt.draw(pose, in: ctx)
        case .suzu: SuzuArt.draw(pose, in: ctx)
        case .marlo: MarloArt.draw(pose, in: ctx)
        }

        if let cursor {
            ctx.saveGState()
            ctx.translateBy(x: -cursor.hotSpot.x, y: cursor.size.height - cursor.hotSpot.y)
            ctx.scaleBy(x: 1, y: -1)
            ctx.draw(cursor.image, in: CGRect(origin: .zero, size: cursor.size))
            ctx.restoreGState()
        }
    }
}
