#!/usr/bin/env bash
# Builds Cull for macOS and packages the .app into ONE file:
#   Cull-<ver>-macos-<arch>.dmg   disk image (double-click, drag app out)
# Pass the arch label as $1 (arm64 | x64); defaults to the host arch.
set -euo pipefail
cd "$(dirname "$0")/.."

arch="${1:-$(uname -m)}"
case "$arch" in
  arm64|aarch64) arch=arm64 ;;
  x86_64|x64)    arch=x64 ;;
esac

version=$(grep -m1 -E '^version:' pubspec.yaml \
  | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
stem="Cull-${version}-macos-${arch}"

echo "==> flutter build macos --release"
flutter build macos --release

app=$(ls -d build/macos/Build/Products/Release/*.app 2>/dev/null | head -1)
[ -n "$app" ] || { echo "no .app in build/macos/Build/Products/Release"; exit 1; }
echo "==> built $app"

mkdir -p dist

hdiutil create -volname "Cull ${version}" -srcfolder "$app" -ov -format UDZO \
  "dist/${stem}.dmg"
echo "==> dist/${stem}.dmg"
