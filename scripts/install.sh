#!/bin/zsh
# Builds the app for this Mac, moves it to /Applications and opens it. Start at Login keeps
# working, because the app stays at the same path.
set -euo pipefail

cd "$(dirname "$0")/.."
TARGET=/Applications/KikoCursor.app

if ! xcode-select -p >/dev/null 2>&1; then
  echo "This needs Apple's Command Line Tools. Run this, click Install in the window that opens," >&2
  echo "wait until that window says it's done, then try again:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi
if [[ ! -w /Applications ]]; then
  echo "This account can't add apps to /Applications, so an administrator needs to install it." >&2
  exit 1
fi
if [[ -e "$TARGET" && ! -w "$TARGET/Contents" ]]; then
  echo "An older KikoCursor in /Applications belongs to another account. Move it to the Trash in Finder, then run this again." >&2
  exit 1
fi

echo "Building Kiko Cursor, which takes a minute or two..."
./scripts/build-app.sh

pkill -x KikoCursor || true
sleep 0.3
rm -rf "$TARGET"
mv dist/KikoCursor.app "$TARGET"
open "$TARGET"
echo "installed $TARGET"
