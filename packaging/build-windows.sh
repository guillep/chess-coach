#!/bin/bash
# Builds packaging/Chessmate-Windows.zip with PharoApplicationGenerator.
# Runs in Cygwin with cmake, clang, make, wget and unzip (see .github/workflows/ci.yml).
# Usage: packaging/build-windows.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"

./pharo Pharo.image eval "($packager) generateWindows"
cd "$WORK/build"
cmake -B . -S .
cmake --build .
powershell -ExecutionPolicy Bypass -File buildZip.ps1
cp ./*.zip "$HERE/Chessmate-Windows.zip"
echo "Built $HERE/Chessmate-Windows.zip $VERSION"
