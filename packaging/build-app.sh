#!/bin/bash
# Builds "Chessmate.app": a fresh Pharo 13 image with the app, and a VM.
# Usage: packaging/build-app.sh [git-ref]   (default: main)
# The bundle is read-only in use: on first launch the image is copied to
# ~/Library/Application Support/Chessmate, where it can be saved and updated.
set -euo pipefail

REF="${1:-main}"
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/build"
WORK="$BUILD/work"
APP="$BUILD/Chessmate.app"

rm -rf "$BUILD"
mkdir -p "$WORK"
cd "$WORK"

curl -fsSL https://get.pharo.org/130+vm | bash

VM="$WORK/pharo-vm/Pharo.app/Contents/MacOS/Pharo"
"$VM" --headless Pharo.image metacello install \
  "github://guillep/chess-coach:$REF/src" BaselineOfChessCoach

# Metacello clones through Iceberg into pharo-local/iceberg; auto update needs them
"$VM" --headless Pharo.image st --quit "$HERE/check-repositories.st"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/image"
cp -R pharo-vm/Pharo.app "$APP/Contents/Resources/Pharo.app"
cp Pharo.image Pharo.changes Pharo*.sources "$APP/Contents/Resources/image/"
cp -R pharo-local "$APP/Contents/Resources/image/pharo-local"
cp "$HERE/open-coach.st" "$APP/Contents/Resources/image/"
cp "$HERE/launcher.sh" "$APP/Contents/MacOS/Chessmate"
chmod +x "$APP/Contents/MacOS/Chessmate"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

SET="$WORK/Chessmate.iconset"
mkdir -p "$SET"
for size in 16 32 128 256 512; do
  sips -z $size $size "$HERE/../assets/chessmate-1024.png" --out "$SET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double "$HERE/../assets/chessmate-1024.png" --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o "$APP/Contents/Resources/Chessmate.icns"

echo "Built $APP"
