#!/bin/zsh
# Builds dist/KikoCursor.app: release binary, icon, Info.plist, ad-hoc signature.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
APP="$ROOT/dist/KikoCursor.app"

swift build -c release 2>&1 | grep -E "error:|Compiling KikoCursor|Build complete" || true
BIN="$(swift build -c release --show-bin-path)/KikoCursor"
[[ -x "$BIN" ]] || { echo "release binary missing" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/KikoCursor"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
"$BIN" --icon "$WORK/icon.png"
mkdir "$WORK/AppIcon.iconset"
for size in 16 32 128 256 512; do
  sips -z $size $size "$WORK/icon.png" --out "$WORK/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double "$WORK/icon.png" --out "$WORK/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$WORK/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Kiko Cursor</string>
  <key>CFBundleDisplayName</key><string>Kiko Cursor</string>
  <key>CFBundleIdentifier</key><string>local.kikocursor.KikoCursor</string>
  <key>CFBundleExecutable</key><string>KikoCursor</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - --timestamp=none "$APP"
echo "built $APP"
