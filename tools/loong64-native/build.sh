#!/usr/bin/env bash
# 在 LoongArch64 Linux 上原生构建 AppFlowy
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

command -v flutter >/dev/null || { echo "缺少 Flutter SDK（dart-loong64 的 loong64 版本）"; exit 1; }
command -v protoc-gen-dart >/dev/null || dart pub global activate protoc_plugin 21.1.2

bash "$HERE/patch-deps.sh"
bash "$HERE/build-rust.sh"
bash "$HERE/build-app.sh"
