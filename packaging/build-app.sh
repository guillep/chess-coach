#!/bin/bash
# Builds "Chess Coach.app": a fresh Pharo 13 image with the app, and a VM.
# Usage: packaging/build-app.sh [git-ref]   (default: main)
# The bundle is read-only in use: on first launch the image is copied to
# ~/Library/Application Support/ChessCoach, where it can be saved and updated.
set -euo pipefail

REF="${1:-main}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/build"
WORK="$BUILD/work"
APP="$BUILD/Chess Coach.app"

rm -rf "$BUILD"
mkdir -p "$WORK"
cd "$WORK"

curl -fsSL https://get.pharo.org/130+vm | bash

VM="$WORK/pharo-vm/Pharo.app/Contents/MacOS/Pharo"
"$VM" --headless Pharo.image metacello install \
  "github://guillep/chess-coach:$REF/src" ChessCoach

# Metacello clones through Iceberg into pharo-local/iceberg; auto update needs them
"$VM" --headless Pharo.image st --quit "$HERE/check-repositories.st"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/image"
cp -R pharo-vm/Pharo.app "$APP/Contents/Resources/Pharo.app"
cp Pharo.image Pharo.changes Pharo*.sources "$APP/Contents/Resources/image/"
cp -R pharo-local "$APP/Contents/Resources/image/pharo-local"
cp "$HERE/open-coach.st" "$APP/Contents/Resources/image/"
cp "$HERE/launcher.sh" "$APP/Contents/MacOS/ChessCoach"
chmod +x "$APP/Contents/MacOS/ChessCoach"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

echo "Built $APP"
