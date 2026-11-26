#!/usr/bin/env bash
# 原生编译 Rust 后端，并生成 Dart protobuf / dart_event
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
APP="$REPO/frontend/appflowy_flutter"

export CARGO_MAKE_WORKING_DIRECTORY="$REPO/frontend"
export FLUTTER_FLOWY_SDK_PATH="appflowy_flutter/packages/appflowy_backend"
# rocksdb 等 C++ 依赖需要显式包含 cstdint
export CXXFLAGS="${CXXFLAGS:-} -include cstdint"
export RUSTFLAGS="${RUSTFLAGS:---cfg tokio_unstable}"

cd "$REPO/frontend/rust-lib"
# 缺少生成物时强制重跑 build.rs
if [ ! -d "$APP/packages/appflowy_backend/lib/protobuf/flowy-folder" ]; then
  for c in flowy-* dart-ffi; do
    [ -f "$c/build.rs" ] && touch "$c/build.rs"
  done
fi

cargo build --profile release -p dart-ffi --features dart

mkdir -p "$APP/linux/flutter/dart_ffi"
cp target/release/libdart_ffi.so "$APP/linux/flutter/dart_ffi/"
cp dart-ffi/binding.h "$APP/linux/flutter/dart_ffi/"
echo "Rust 后端完成"
