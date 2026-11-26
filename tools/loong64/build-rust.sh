#!/usr/bin/env bash
# 交叉编译 Rust 后端（dart-ffi），并在首次构建时生成 Dart protobuf / dart_event
set -euo pipefail
. "$(dirname "$0")/config.sh"

command -v protoc-gen-dart >/dev/null || dart pub global activate protoc_plugin 21.1.2

export CARGO_MAKE_WORKING_DIRECTORY="$REPO_ROOT/frontend"
export FLUTTER_FLOWY_SDK_PATH="appflowy_flutter/packages/appflowy_backend"

cd "$RUST_LIB"
# 代码生成产物缺失时重跑 build.rs
if [ ! -d "$APP_DIR/packages/appflowy_backend/lib/protobuf/flowy-folder" ]; then
  for c in flowy-* dart-ffi; do
    [ -f "$c/build.rs" ] && touch "$c/build.rs"
  done
fi

cargo build --profile release -p dart-ffi --target "$RUST_TARGET" --features dart

mkdir -p "$APP_DIR/linux/flutter/dart_ffi"
cp "target/$RUST_TARGET/release/libdart_ffi.so" "$APP_DIR/linux/flutter/dart_ffi/"
cp dart-ffi/binding.h "$APP_DIR/linux/flutter/dart_ffi/"
echo "Rust 后端完成"
