#!/bin/zsh
# Builds the app, moves it to /Applications and opens it. Start at Login keeps working,
# because the app stays at the same path.
set -euo pipefail

cd "$(dirname "$0")/.."
TARGET=/Applications/KikoCursor.app

./scripts/build-app.sh

pkill -x KikoCursor || true
sleep 0.3
rm -rf "$TARGET"
mv dist/KikoCursor.app "$TARGET"
open "$TARGET"
echo "installed $TARGET"
