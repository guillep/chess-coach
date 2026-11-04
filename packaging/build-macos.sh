#!/bin/bash
# Builds packaging/work/build/Chessmate.app and packaging/Chessmate-macOS.zip
# (the release asset the updater downloads) with PharoApplicationGenerator.
# Usage: packaging/build-macos.sh   (RUN_TESTS=1 to run the tests on the image)
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"

./pharo Pharo.image eval "($packager) generateMacOS"
cd "$WORK/build"
chmod +x build.sh
JUST_BUILD=1 ./build.sh
codesign --force --deep -s - Chessmate.app
ditto -c -k --keepParent Chessmate.app "$HERE/Chessmate-macOS.zip"
echo "Built $WORK/build/Chessmate.app $VERSION"
