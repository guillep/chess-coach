#!/bin/bash
# Starts the app: copies the image out of the bundle the first time, then runs it.
set -euo pipefail

RESOURCES="$(cd "$(dirname "$0")/../Resources" && pwd)"
DATA="$HOME/Library/Application Support/Chessmate"

if [ ! -f "$DATA/Pharo.image" ]; then
  mkdir -p "$DATA"
  cp -R "$RESOURCES/image/." "$DATA/"
fi

cd "$DATA"
exec "$RESOURCES/Pharo.app/Contents/MacOS/Pharo" --headless "$DATA/Pharo.image" \
  st "$DATA/open-coach.st"
