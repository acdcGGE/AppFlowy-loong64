#!/usr/bin/env bash
# 构建 Flutter Linux loong64 应用
set -euo pipefail
. "$(dirname "$0")/config.sh"
export PATH="$TOOLWRAP:$PATH"

cd "$APP_DIR"
flutter pub get
python3 "$(dirname "$0")/pubs.py"

# 旧构建缓存若把安装前缀指向别处，纠正到 bundle
CACHE_FILE="$APP_DIR/build/linux/loong64/release/CMakeCache.txt"
BUNDLE_DIR="$APP_DIR/build/linux/loong64/release/bundle"
if [ -f "$CACHE_FILE" ] && ! grep -qx "CMAKE_INSTALL_PREFIX:PATH=$BUNDLE_DIR" "$CACHE_FILE"; then
  sed -i "s|^CMAKE_INSTALL_PREFIX:PATH=.*|CMAKE_INSTALL_PREFIX:PATH=$BUNDLE_DIR|" "$CACHE_FILE"
fi

flutter build linux --release \
  --target-platform linux-loong64 \
  --target-sysroot="$SYSROOT" \
  --no-tree-shake-icons
echo "应用构建完成：$APP_DIR/build/linux/loong64/release/bundle"
