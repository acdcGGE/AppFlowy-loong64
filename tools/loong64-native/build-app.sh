#!/usr/bin/env bash
# 修补 pub 缓存并构建 Flutter 应用（loong64 原生）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
APP="$REPO/frontend/appflowy_flutter"

cd "$APP"
flutter pub get
python3 "$HERE/pub-cache.py"
flutter build linux --release --target-platform linux-loong64 --no-tree-shake-icons
echo "构建完成：$APP/build/linux/loong64/release/bundle"
