# Kiko Cursor

Turns your Mac's pointer into Kiko, an original chibi fox spirit who lives in your menu bar. Kiko's fingertip is the pointer: clicks land exactly where it points.

![Kiko's poses on light and dark, with a red cross marking the real mouse position](docs/poses.png)

## Run it

```bash
./scripts/build-app.sh
```

```bash
open dist/KikoCursor.app
```

Needs macOS 14 or later and Swift (the Command Line Tools are enough). It asks for no permissions: no Accessibility, no Input Monitoring, no Screen Recording.

- **Menu bar paw:** show or hide Kiko, change the size and options, quit.
- **⌃⌥K:** swap back to the normal pointer from anywhere.
- **Quitting or crashing** brings the normal pointer straight back, because macOS ties the hidden state to the process.

## What Kiko does

| When | Kiko |
| --- | --- |
| You move the mouse | Flies after the pointing hand, leaning, with scarf and tail trailing |
| You click | Squashes, smiles and throws sparkles |
| You hold the button | Looks focused |
| You hover a link | Eyes sparkle and ears perk up |
| The app wants a text, resize or crosshair cursor | Steps aside and shows the real cursor, so precision work stays readable |
| You shake the mouse | Gets dizzy |
| 25 seconds idle | Falls asleep, with Zs |
| You type | Fades to 25% until the mouse moves |
| Idle over a full-screen app, such as a video | Disappears until the mouse moves |
| You reach a screen edge | Moves to the other side of the pointer, to stay on screen |
| macOS insists on the real pointer, as in Mission Control | Steps aside until macOS lets go, so there's only ever one pointer |

Kiko is excluded from screen capture by default, like the normal pointer, with a menu option to include Kiko for demos. This exclusion hasn't been confirmed on macOS 26 yet, and some capture tools may ignore it.

## How it works

macOS has no public way to replace the system cursor, so the app does three things:

1. **Hides the real pointer** with `CGDisplayHideCursor`, plus the private `SetsCursorInBackground` connection property that makes it work while another app is frontmost. It's looked up at runtime: if a future macOS removes it, you get both pointers rather than a crash. Switching apps and reaching the menu bar bring the pointer back, so it's checked and re-hidden every frame.
2. **Follows the mouse with a click-through window** at cursor level, with the hotspot at its exact centre.
3. **Draws Kiko procedurally** with Core Graphics from spring physics, so there are no image assets and the art is sharp at any size.

`NSCursor.currentSystem` still reports what the frontmost app wants while the pointer is hidden, which is what makes Kiko context-aware.

| Path | What's in it |
| --- | --- |
| `Sources/KikoCore/Rig.swift` | Mouse input to pose: physics, expressions, screen edges. No AppKit |
| `Sources/KikoCore/Renderer.swift` | Pose to pixels: all of the character art |
| `Sources/KikoCursor/Overlay.swift` | The window, frame loop and drawing surface |
| `Sources/KikoCursor/CursorHider.swift` | Hiding and restoring the real pointer |
| `Sources/KikoCursor/SystemCursorWatcher.swift` | Working out which cursor the app wants |
| `Sources/KikoCursor/AppDelegate.swift` | Menu bar, hot key, lock screen and sleep handling |

## Checking it

```bash
swift run KikoCursor --check
```

Logic checks through the real physics: fingertip accuracy, every pose fits the window, screen edges, reactions, recovery from stalls.

```bash
swiftc -O scripts/livecheck.swift -o /tmp/livecheck -framework AppKit && /tmp/livecheck "$PWD/dist/KikoCursor.app/Contents/MacOS/KikoCursor"
```

Runs the app and checks from outside it, through the window system, that the pointer is hidden, the window tracks the mouse, toggling works, a returned pointer is re-hidden quickly, and a clean quit or `kill -9` restores the pointer. It moves your real mouse for a few seconds but never clicks.

```bash
swift run KikoCursor --sheet sheet.png
```

Renders every pose through the real physics, on light and dark, with a red cross on the hotspot. Art changes are easiest to judge here.

Other developer flags: `--portrait PATH`, `--bench`, `--exit-after SECONDS`, `--dump-frame PATH`, `--print-status`, `--test-unhide-every SECONDS`. Running `pkill -USR1 KikoCursor` does the same as ⌃⌥K.

## Known limits

- **Distribution:** the private API rules out the Mac App Store. Selling it means a notarized direct download, which needs an Apple Developer ID. The current build has only an ad-hoc signature, so on other Macs Gatekeeper will block it.
- **Latency:** a window can't quite match the hardware cursor, so fast flicks may trail slightly. This hasn't been measured.
- **Secure screens:** the app restores the normal pointer when the screen locks. Some system-level surfaces may not show Kiko.
- **Multiple displays:** the code handles them, but so far it has only run on a single built-in display.
- **Crowded menu bars:** on a notched Mac, macOS can hide items that don't fit. If the paw is missing, ⌃⌥K still works, and `pkill KikoCursor` quits.
- **Spaces swipes:** the window list reports windows sliding during a swipe. Whether Kiko visibly moves with it for that half second hasn't been checked by eye.
- **Characters:** Kiko is original. Named anime characters are copyrighted, so shipping one needs a licence from the rights holder.
