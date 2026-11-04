# Shared by build-macos.sh and build-windows.sh: a fresh Pharo 13 image with
# Chessmate, then MMPackager writes PharoApplicationGenerator's project in
# $WORK/build. Sourced with HERE set; sets WORK and VERSION.
set -euo pipefail

ROOT="$(cd "$HERE/.." && pwd)"
WORK="$HERE/work"
# The bundle version: the newest v1.2.3 tag reachable from HEAD
VERSION="$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || echo v0.0.0)"
VERSION="${VERSION#v}"

# Paths as Pharo sees them: Windows paths under Cygwin
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
ROOT_PATH="$(native "$ROOT")"
WORK_PATH="$(native "$WORK")"

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"
curl -fsSL https://get.pharo.org/64/130+vm | bash

./pharo Pharo.image metacello install "tonel://$ROOT_PATH/src" BaselineOfChessCoach

if [ "${RUN_TESTS:-0}" = 1 ]; then
  ./pharo Pharo.image test --fail-on-failure "ChessCoach-Tests" "Mamotreto-Tests"
fi

packager="MMPackager new
  app: ChessmateApp;
  version: '$VERSION';
  bundleIdentifier: 'org.chessmate.app';
  iconPng: '$ROOT_PATH/assets/chessmate-1024.png';
  outputDirectory: '$WORK_PATH/build';
  yourself"

# Two steps: saving the image inside the generating script would resume
# that script when the packaged app starts
./pharo Pharo.image eval --save "($packager) prepareImage"
