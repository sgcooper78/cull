#!/usr/bin/env bash
# Builds Cull for Linux and packages it into ONE file in ./dist:
#   Cull-<ver>-linux-x64.AppImage   self-contained executable (chmod +x, run)
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(grep -m1 -E '^version:' pubspec.yaml \
  | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
name="Cull-${version}-linux-x64"
bundle="build/linux/x64/release/bundle"

echo "==> flutter build linux --release"
flutter build linux --release

bin=$(find "$bundle" -maxdepth 1 -type f -perm -u+x | head -1)
[ -n "$bin" ] || { echo "no executable in $bundle"; exit 1; }
echo "==> built $bin"

mkdir -p dist

# --- AppImage -----------------------------------------------------------
appdir="build/Cull.AppDir"
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin"
cp -r "$bundle/." "$appdir/usr/bin/"

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/usr/bin/cull" "$@"
EOF
chmod +x "$appdir/AppRun"

cat > "$appdir/cull.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Cull
Comment=Triage files on disk
Exec=cull
Icon=cull
Categories=Utility;FileTools;
Terminal=false
EOF

if command -v convert >/dev/null 2>&1; then
  convert -size 256x256 xc:'#3A6EA5' "$appdir/cull.png"
else
  # minimal 1x1 PNG so appimagetool has an icon
  base64 -d > "$appdir/cull.png" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
EOF
fi

tool_ai="build/appimagetool-x86_64.AppImage"
if [ ! -x "$tool_ai" ]; then
  curl -fsSL -o "$tool_ai" \
    https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
  chmod +x "$tool_ai"
fi

APPIMAGE_EXTRACT_AND_RUN=1 "$tool_ai" "$appdir" "dist/$name.AppImage"
chmod +x "dist/$name.AppImage"
echo "==> dist/$name.AppImage"
