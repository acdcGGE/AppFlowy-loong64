#!/usr/bin/env bash
# LoongArch64 构建配置：所有路径均相对或由环境变量给出
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 工作目录（SDK、sysroot、补丁源码、下载缓存）
ROOT="${LOONG64_ROOT:-$HOME/loong64-build}"
DL="$ROOT/dl"
FLUTTER_SDK="$ROOT/flutter-sdk"
PATCHED="$ROOT/patched"
SYSROOT="$ROOT/sysroot"
TOOLWRAP="$ROOT/toolwrap"

# 本仓库内路径
RUST_LIB="$REPO_ROOT/frontend/rust-lib"
APP_DIR="$REPO_ROOT/frontend/appflowy_flutter"
RUST_TARGET=loongarch64-unknown-linux-gnu
CROSS_PREFIX="${CROSS_PREFIX:-loongarch64-linux-gnu-}"

# 版本与下载地址
FLUTTER_VERSION=3.47.4
FLUTTER_SDK_URL="https://github.com/dart-loong64/flutter/releases/download/${FLUTTER_VERSION}/flutter_linux_loong64_${FLUTTER_VERSION}-stable.tar.xz"
DART_VERSION=3.13.3
DART_X64_URL="https://github.com/dart-loong64/dart/releases/download/${DART_VERSION}/dartsdk-linux-x64-release.tar.gz"
GEN_SNAPSHOT_URL="https://github.com/dart-loong64/dart/releases/download/${DART_VERSION}/gen_snapshot_linux_x64_linux_loong64"
ENGINE_REVISION=06a2e2a110089dff50fe635cffd2a61e1b24fbcd
ENGINE_BASE="https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE_REVISION}"
EDITOR_REPO="https://github.com/AppFlowy-IO/appflowy-editor.git"
EDITOR_REF=470c4e77c71b63f693ce0923a927afcd667d6f3b
PLUGINS_REPO="https://github.com/AppFlowy-IO/AppFlowy-plugins.git"
PLUGINS_REF=4efcff720ed01dd4d0f5f88a9f1ff6f79f423caa
LOONG64_MIRROR="${LOONG64_MIRROR:-https://mirrors.nju.edu.cn/loongarch/archlinux}"
SDL2_VERSION=2.32.10
SDL2_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/SDL2-${SDL2_VERSION}.tar.gz"

# 工具链 / 包管理
PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export PUB_HOSTED_URL
RUST_TOOLCHAIN="${RUST_TOOLCHAIN:-stable}"
export RUSTUP_TOOLCHAIN="$RUST_TOOLCHAIN"
export CARGOKIT_TOOLCHAIN="$RUST_TOOLCHAIN"
export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY:-1}"

export PATH="$HOME/.cargo/bin:$HOME/.pub-cache/bin:$FLUTTER_SDK/bin:$PATH"
export CARGO_TARGET_LOONGARCH64_UNKNOWN_LINUX_GNU_LINKER="$TOOLWRAP/loongarch64-cross-gcc"
export CARGO_TARGET_LOONGARCH64_UNKNOWN_LINUX_GNU_AR="${CROSS_PREFIX}ar"
export CARGO_TARGET_LOONGARCH64_UNKNOWN_LINUX_GNU_STRIP="${CROSS_PREFIX}strip"
export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
export PKG_CONFIG_ALLOW_CROSS=1
export CC_loongarch64_unknown_linux_gnu="${CROSS_PREFIX}gcc"
export CXX_loongarch64_unknown_linux_gnu="${CROSS_PREFIX}g++"
export AR_loongarch64_unknown_linux_gnu="${CROSS_PREFIX}ar"
export CFLAGS_loongarch64_unknown_linux_gnu="-O2 -fPIC -I$SYSROOT/usr/include"
export CXXFLAGS_loongarch64_unknown_linux_gnu="-O2 -fPIC -I$SYSROOT/usr/include -include cstdint"
export RUSTFLAGS="${RUSTFLAGS:---cfg tokio_unstable}"

mkdir -p "$DL" "$ROOT"
