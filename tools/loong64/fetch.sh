#!/usr/bin/env bash
# 下载 Flutter loong64 SDK、Dart x64 SDK、交叉 gen_snapshot、宿主引擎工具
set -euo pipefail
. "$(dirname "$0")/config.sh"

dl() { # dl <url> <file>
  [ -s "$2" ] || { echo "GET $1"; curl -fkL --retry 3 -o "$2.part" "$1"; mv "$2.part" "$2"; }
}

dl "$FLUTTER_SDK_URL" "$DL/flutter_linux_loong64_${FLUTTER_VERSION}-stable.tar.xz"
dl "$DART_X64_URL" "$DL/dartsdk-linux-x64-release.tar.gz"
dl "$GEN_SNAPSHOT_URL" "$DL/gen_snapshot_linux_x64_linux_loong64"
dl "$ENGINE_BASE/linux-x64/artifacts.zip" "$DL/engine-linux-x64-artifacts.zip"

[ -d "$FLUTTER_SDK" ] || tar -xf "$DL/flutter_linux_loong64_${FLUTTER_VERSION}-stable.tar.xz" -C "$ROOT"
# 解包目录名为 flutter，统一改为 flutter-sdk
[ -d "$ROOT/flutter" ] && [ ! -d "$FLUTTER_SDK" ] && mv "$ROOT/flutter" "$FLUTTER_SDK"
echo "下载完成：$DL"
