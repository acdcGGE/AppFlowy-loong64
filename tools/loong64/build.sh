#!/usr/bin/env bash
# 一键构建：SDK -> sysroot -> 依赖补丁 -> Rust -> Flutter -> 打包
set -euo pipefail
HERE="$(dirname "$0")"

bash "$HERE/fetch.sh"
bash "$HERE/setup-flutter.sh"
bash "$HERE/make-toolchain.sh"
bash "$HERE/make-sysroot.sh"
bash "$HERE/patch-deps.sh"
bash "$HERE/build-rust.sh"
bash "$HERE/build-app.sh"
bash "$HERE/package.sh"
