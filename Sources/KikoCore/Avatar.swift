import CoreGraphics

/// Who's on screen. The raw value is what gets saved in the app's settings.
public enum Avatar: String, CaseIterable {
    case kiko, suzu, marlo

    public var name: String { rawValue.capitalized }

    public var menuTitle: String {
        switch self {
        case .kiko: return "Kiko the Fox Spirit"
        case .suzu: return "Suzu the Ninja"
        case .marlo: return "Marlo the Pirate"
        }
    }

    var motion: Motion {
        switch self {
        case .kiko: return .kiko
        case .suzu: return .suzu
        case .marlo: return .marlo
        }
    }
}

/// One hanging chain: a scarf end, a ponytail, a coat tail.
struct ChainSpec {
    var nodes: Int
    var seg: CGFloat
    var anchor: CGPoint         // from the body centre; x mirrors with the side the body is on
    var pull: CGPoint           // steady force; x mirrors too
    var breeze: CGFloat         // how much the idle breeze pushes it, and which way
    var flutter: CGFloat        // share of the ripple that travels down it
    var phase: CGFloat
    var followsBody = false     // anchor leans and bobs with the body, for anchors far from the neck
}

/// What a click throws out from the pointer.
struct Burst {
    var count: Int
    var speed: ClosedRange<CGFloat>
    var life: ClosedRange<CGFloat>
    var size: ClosedRange<CGFloat>
    var spin: CGFloat
    var drag: CGFloat           // share of the speed left after one second
    var gravity: CGFloat = 0
    var lift: CGFloat = 0       // extra speed straight up
    var shrink: CGFloat = 0.6   // share of the size lost by the end of its life
}

/// How a character moves. The Rig is the same for everyone; only these numbers differ.
struct Motion {
    var omega: CGFloat          // how tightly the body follows the pointer
    var zeta: CGFloat
    var bobSize: CGFloat
    var bobRate: CGFloat
    var rollSize: CGFloat       // a slow side-to-side rock, on top of leaning into movement
    var rollRate: CGFloat
    var chainA: ChainSpec
    var chainB: ChainSpec
    var burst: Burst
    var poofs = false           // a click hides the body in a puff of smoke for a moment

    static let kiko = Motion(
        omega: 12.5, zeta: 0.68,
        bobSize: 0.55, bobRate: 2.1,
        rollSize: 0, rollRate: 0,
        chainA: ChainSpec(nodes: 7, seg: 5, anchor: CGPoint(x: 5.5, y: 0.5), pull: CGPoint(x: 150, y: 150),
                          breeze: 1, flutter: 1, phase: 0),
        chainB: ChainSpec(nodes: 6, seg: 4.2, anchor: CGPoint(x: 4, y: 1.5), pull: CGPoint(x: 70, y: 210),
                          breeze: -1, flutter: 0.8, phase: 2.1),
        burst: Burst(count: 6, speed: 70...140, life: 0.34...0.48, size: 2.6...5.2, spin: 9, drag: 0.02))
}
