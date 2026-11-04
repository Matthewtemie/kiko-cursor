# Kiko Cursor

Turns your Mac's pointer into an original chibi character who lives in your menu bar. Pick Kiko the fox spirit, Suzu the ninja or Marlo the pirate. The character's fingertip is the pointer: clicks land exactly where it points.

![Kiko, Suzu and Marlo at rest, on a click, over a link and asleep, on light and dark](docs/avatars.png)

![Kiko's poses on light and dark, with a red cross marking the real mouse position](docs/poses.png)

## Install

For macOS 13 or later, on Apple silicon or Intel. So far it has only run on macOS 26 on an Apple silicon Mac, so anything else is untested: see [Known limits](#known-limits).

### Download the app

You don't need any developer tools for this.

1. Download [KikoCursor.zip](https://github.com/Matthewtemie/kiko-cursor/releases/latest/download/KikoCursor.zip) and double-click it to unzip. Safari may already have done this for you.
2. Drag **KikoCursor** into your **Applications** folder.
3. Double-click it there. macOS refuses the first time and says it could not verify the app is free of malware, because the app has no paid Apple Developer ID and Apple hasn't checked it. Click **Done**, not **Move to Trash**.
4. Open **System Settings**, go to **Privacy & Security** and scroll down to **Security**. Click **Open Anyway** next to KikoCursor, then confirm. macOS may ask for your Mac password. The button only stays for about an hour, so if it isn't there, double-click the app again and come back.

A paw appears in your menu bar and your pointer becomes Kiko. You need to do this again only when you download a new version.

If you'd rather not click past that warning, read the code and build it yourself.

### Build it yourself

This needs Apple's Command Line Tools, which are free. Open **Terminal**, which is in **Applications > Utilities**. If you don't have the tools yet, run this, click **Install** in the window that opens, and wait until that window says it's done. If it says they're already installed, carry on.

```bash
xcode-select --install
```

Then run:

```bash
git clone https://github.com/Matthewtemie/kiko-cursor.git
cd kiko-cursor
./scripts/install.sh
```

That builds the app for your Mac, moves it to `/Applications` and opens it, which takes a minute or two. macOS doesn't block it, because it was built on your own Mac.

To update, go back to the `kiko-cursor` folder in Terminal and run `git pull`, then `./scripts/install.sh`.

It has only been built with Swift 6.4 so far. If your tools can't build it, use the download.

### Uninstall

1. If you switched on **Start at Login**, switch it off in the paw menu.
2. Choose **Quit Kiko Cursor** from the paw menu. Your normal pointer comes back.
3. Move **KikoCursor** from **Applications** to the Trash. If you built it yourself, you can delete the `kiko-cursor` folder too.

To remove its saved settings too, run this in Terminal:

```bash
defaults delete local.kikocursor.KikoCursor
```

## Using it

The app asks for no permissions: no Accessibility, no Input Monitoring, no Screen Recording. It has no network code and never sees what you type. To fade while you type, it only asks macOS how long ago a key was pressed.

- **Menu bar paw:** show or hide the character, pick who it is under **Avatar**, change the size and options, start at login, quit. Your pick is remembered.
- **Control-Option-K (⌃⌥K):** swap back to the normal pointer from anywhere.
- **Quitting or crashing** brings the normal pointer straight back, because macOS ties the hidden state to the process.
- **Start at Login** remembers where the app is, so drag the app to **Applications** first. If you later move it, it won't start at login. Opening the app from its new location and switching the option off and on should fix that, though this hasn't been tested.

### If the paw is missing

macOS can hide menu bar items that don't fit, mainly on Macs with a notch.

- **Control-Option-K** still swaps between the character and the normal pointer.
- **To quit,** open **Activity Monitor**, which is in **Applications > Utilities**, search for Kiko, select it and click the stop button at the top of the window.
- **To stop it starting at login,** switch it off in **System Settings > General > Login Items**.

## What they do

All three react to the same things and use the same pointing arm, so the click point can't differ between them. This table shows Kiko, and the next one shows how Suzu and Marlo differ.

| When | The character |
| --- | --- |
| You move the mouse | Flies after the pointing hand, leaning, with scarf and tail trailing |
| You click | Squashes, smiles and throws sparkles |
| You hold the button | Looks focused |
| You hover a link | Eyes sparkle |
| The app wants a text, resize or crosshair cursor | Steps aside and shows the real cursor, so precision work stays readable |
| You shake the mouse | Gets dizzy |
| 25 seconds idle | Falls asleep, with Zs |
| You type | Fades to 25% until the mouse moves |
| Idle over a full-screen app, such as a video | Disappears until the mouse moves |
| You reach a screen edge | Moves to the other side of the pointer, to stay on screen |
| macOS insists on the real pointer, as in Mission Control | Steps aside until macOS lets go, so there's only ever one pointer |

What sets each one apart:

| | Kiko | Suzu | Marlo |
| --- | --- | --- | --- |
| **Look** | Fox ears and tail, red scarf | Teal hood, plum ponytail, small bell on a cord | Navy tricorn with a feather, brass-buttoned coat, parrot on the shoulder |
| **Moves** | Flies after the pointer | Quick and tight | Bobs and rocks as if on waves |
| **On a click** | Throws sparkles | Vanishes in a puff of smoke and throws paper shuriken; the arm stays, so you can still see where you're pointing | Scatters gold coins |
| **Over a link** | Eyes sparkle | Eyes light up | Raises a spyglass, and the parrot hops up to the hat |
| **Asleep** | Nods off | Hugs a scroll | Tips the hat over the eyes |

The character is left out of screenshots by default, like the normal pointer. It's also left out of screen shares and recordings, where the normal pointer would usually show, so viewers may see no pointer at all. To show it, switch on **Show in Screenshots and Recordings** in the paw menu before you share. This hasn't been tested in meeting apps, and some capture tools may ignore the setting.

## How it works

macOS has no public way to replace the system cursor, so the app does three things:

1. **Hides the real pointer** with `CGDisplayHideCursor`, plus the private `SetsCursorInBackground` connection property that makes it work while another app is frontmost. It's looked up at runtime: if a future macOS removes it, you get both pointers rather than a crash. Switching apps and reaching the menu bar bring the pointer back, so it's checked and re-hidden every frame.
2. **Follows the mouse with a click-through window** at cursor level, with the hotspot at its exact centre.
3. **Draws the character procedurally** with Core Graphics from spring physics, so there are no image assets and the art is sharp at any size.

`NSCursor.currentSystem` still reports what the frontmost app wants while the pointer is hidden, which is what makes the character context-aware.

| Path | What's in it |
| --- | --- |
| `Sources/KikoCore/Rig.swift` | Mouse input to pose: physics, expressions, screen edges. No AppKit |
| `Sources/KikoCore/Avatar.swift` | Who's on screen, and the numbers that make each one move differently |
| `Sources/KikoCore/KikoArt.swift`, `SuzuArt.swift`, `MarloArt.swift` | Pose to pixels: each character's art |
| `Sources/KikoCore/DrawKit.swift` | What they share, including the pointing arm |
| `Sources/KikoCore/Renderer.swift` | Picks the character's art for a pose and draws the real cursor when needed |
| `Sources/KikoCursor/Overlay.swift` | The window, frame loop and drawing surface |
| `Sources/KikoCursor/FrameClock.swift` | Frame timing: `CADisplayLink` on macOS 14 and later, `CVDisplayLink` on macOS 13 |
| `Sources/KikoCursor/CursorHider.swift` | Hiding and restoring the real pointer |
| `Sources/KikoCursor/SystemCursorWatcher.swift` | Working out which cursor the app wants |
| `Sources/KikoCursor/AppDelegate.swift` | Menu bar, hot key, lock screen and sleep handling |

## Checking it

```bash
swift run KikoCursor --check
```

Checks through the real physics and drawing, for every character: fingertip accuracy, nothing hides the finger, all ink fits the window, screen edges, reactions, recovery from stalls, settling to the idle frame rate, swapping characters.

```bash
swiftc -O scripts/livecheck.swift -o /tmp/livecheck -framework AppKit && pkill -x KikoCursor; /tmp/livecheck /Applications/KikoCursor.app/Contents/MacOS/KikoCursor
```

Quits any running Kiko, then runs the app and checks from outside it, through the window system, that the pointer is hidden, the window tracks the mouse, toggling works, a returned pointer is re-hidden quickly, and a clean quit or `kill -9` restores the pointer. It moves your real mouse for a few seconds but never clicks. It won't run with the screen locked or the display asleep, because no frames are drawn then. Add `--test-core-video-clock` after the app's path to test macOS 13's frame clock on a newer system.

```bash
arch -x86_64 /Applications/KikoCursor.app/Contents/MacOS/KikoCursor --check
```

Runs the checks on the Intel half of the app, on an Apple silicon Mac with Rosetta installed. This needs the downloaded app or `dist/KikoCursor.app` from `./scripts/package-release.sh`, because what `install.sh` builds has no Intel half. For the live check, copy the app, keep only its Intel half with `lipo -thin x86_64`, re-sign the copy with `codesign --force --sign -`, and give livecheck that copy's binary. Rosetta doesn't show how fast the app is on a real Intel Mac.

```bash
swift run KikoCursor --avatar suzu --sheet sheet.png
```

Renders every pose through the real physics, on light and dark, with a red cross on the hotspot. Art changes are easiest to judge here. Leave out `--avatar` for Kiko; `--lineup PATH` puts all three side by side.

`--avatar NAME` also shows that character for one run without saving the choice. `--test-avatar-menu DIR` picks each character through the real menu, saves what's on screen to `DIR`, puts your saved choice back and quits.

Other developer flags: `--portrait PATH`, `--bench`, `--exit-after SECONDS`, `--dump-frame PATH`, `--print-status`, `--test-unhide-every SECONDS`, `--test-core-video-clock`, `--login-item on|off|status` (from inside the `.app` only). Running `pkill -USR1 KikoCursor` does the same as ⌃⌥K.

```bash
./scripts/package-release.sh
```

Builds `dist/KikoCursor.zip`, the one app for Apple silicon and Intel that goes on the Releases page. This has only been done with Swift 6.4, no Xcode needed. Older tools may only be able to build for one kind of Mac, which is all `install.sh` does.

## Known limits

- **Distribution:** the private API rules out the Mac App Store. The app has no Apple Developer ID, only an ad-hoc signature, which is why macOS blocks the download until you choose **Open Anyway**.
- **macOS 13 and Intel:** so far the app has only run on macOS 26 on an Apple silicon Mac. There, macOS 13's frame clock has been tested by forcing it on, and the Intel build by running it under Rosetta. It has never run on real macOS 13 or a real Intel Mac, and CPU use on Intel is unmeasured.
- **Latency:** a window can't quite match the hardware cursor, so fast flicks may trail slightly. This hasn't been measured.
- **Secure screens:** the app restores the normal pointer when the screen locks. Some system-level surfaces may not show the character.
- **Multiple displays:** the code handles them, but so far it has only run on a single built-in display.
- **Crowded menu bars:** on a notched Mac, macOS can hide items that don't fit. See [If the paw is missing](#if-the-paw-is-missing).
- **Dragging files:** macOS's green plus and no-entry sign look like the plain arrow to the app, so the character shows instead of them.
- **Two copies:** if you open a second copy from another folder, both run, so you get two characters until you quit one.
- **Accessibility pointer settings:** a larger or recoloured pointer hasn't been tried, and the character may then step aside all the time.
- **CPU use:** the character keeps animating, so the app never goes fully idle while it's showing. On an M4 Pro it uses about 3% of one core when still and about 25% during fast mouse movement, and it averaged about 10% over an hour of ordinary use. Slower Macs will use more, and battery use hasn't been measured.
- **Spaces swipes:** the window list reports windows sliding during a swipe. Whether the character visibly moves with it for that half second hasn't been checked by eye.
- **Characters:** Kiko, Suzu and Marlo are all original. Named anime characters are copyrighted, so adding one, or something drawn to look like one, needs a licence from the rights holder.

## Licence

MIT. See [LICENSE](LICENSE).
