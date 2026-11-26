#!/usr/bin/env bash
# 精简、附带运行库并打包
set -euo pipefail
. "$(dirname "$0")/config.sh"

BUNDLE="$APP_DIR/build/linux/loong64/release/bundle"
DIST="$ROOT/dist"
VERSION="$(awk '/^version:/{print $2; exit}' "$APP_DIR/pubspec.yaml")"
NAME="AppFlowy-linux-loong64-$VERSION"
[ -d "$BUNDLE" ] || { echo "先运行 build-app.sh"; exit 1; }

"${CROSS_PREFIX}strip" --strip-unneeded "$BUNDLE/AppFlowy" "$BUNDLE"/lib/*.so

rm -rf "$DIST/$NAME"
mkdir -p "$DIST/$NAME"
cp -a "$BUNDLE/." "$DIST/$NAME/"

# media_kit 运行期 dlopen 的库
cp -L "$SYSROOT/usr/lib/libmpv.so.2" "$DIST/$NAME/lib/libmpv.so.2.6.0"
ln -sf libmpv.so.2.6.0 "$DIST/$NAME/lib/libmpv.so.2"
ln -sf libmpv.so.2 "$DIST/$NAME/lib/libmpv.so"
cp -L "$SYSROOT/usr/lib/libSDL2-2.0.so.0" "$DIST/$NAME/lib/"
cp -L "$SYSROOT/usr/lib/libmujs.so" "$DIST/$NAME/lib/"

cat > "$DIST/$NAME/run.sh" <<'EOF'
#!/bin/sh
DIR=$(cd "$(dirname "$0")" && pwd)
export LD_LIBRARY_PATH="$DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$DIR/AppFlowy" "$@"
EOF
chmod +x "$DIST/$NAME/run.sh"

tar -C "$DIST" -czf "$DIST/$NAME.tar.gz" "$NAME"
echo "打包完成：$DIST/$NAME.tar.gz"
