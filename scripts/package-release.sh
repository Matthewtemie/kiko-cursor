#!/bin/zsh
# Builds dist/KikoCursor.zip, the app for Apple silicon and Intel that goes on the Releases page.
set -euo pipefail

cd "$(dirname "$0")/.."
./scripts/build-app.sh --universal

rm -f dist/KikoCursor.zip
ditto -c -k --norsrc --noextattr --keepParent dist/KikoCursor.app dist/KikoCursor.zip
echo "built dist/KikoCursor.zip"
