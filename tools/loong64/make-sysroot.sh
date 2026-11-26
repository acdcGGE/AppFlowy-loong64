#!/usr/bin/env bash
# 构建 loong64 sysroot：pacman 包 + glibc 头库 + SDL2（源码）+ libmpv 依赖修补
set -euo pipefail
. "$(dirname "$0")/config.sh"

python3 "$(dirname "$0")/build_sysroot.py"

# glibc 头/库/crt 从交叉工具链补齐（路径由编译器推导）
TC_ROOT="${CROSS_TOOLCHAIN_ROOT:-}"
if [ -z "$TC_ROOT" ]; then
  TC_ROOT="$(dirname "$(dirname "$(command -v "${CROSS_PREFIX}gcc")")")/${CROSS_PREFIX%-}"
fi
mkdir -p "$SYSROOT/usr/include" "$SYSROOT/usr/lib"
cp -an "$TC_ROOT"/include/. "$SYSROOT/usr/include/" 2>/dev/null || true
cp -an "$TC_ROOT"/lib/. "$SYSROOT/usr/lib/" 2>/dev/null || true
ln -sfn usr/lib "$SYSROOT/lib"
ln -sfn usr/lib "$SYSROOT/lib64"

# SDL2：仓库无 loong64 包，源码交叉编译（libmpv 依赖）
cd "$ROOT"
[ -s "$DL/SDL2-${SDL2_VERSION}.tar.gz" ] || curl -fkL -o "$DL/SDL2-${SDL2_VERSION}.tar.gz" "$SDL2_URL"
rm -rf "SDL2-${SDL2_VERSION}" sdl2-build
tar -xf "$DL/SDL2-${SDL2_VERSION}.tar.gz"
cmake -S "SDL2-${SDL2_VERSION}" -B sdl2-build \
  -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=loongarch64 \
  -DCMAKE_C_COMPILER="$TOOLWRAP/clang" -DCMAKE_CXX_COMPILER="$TOOLWRAP/clang++" \
  -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DCMAKE_BUILD_TYPE=Release \
  -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TEST=OFF
cmake --build sdl2-build -j"$(nproc)"
cmake --install sdl2-build

# libmpv 的 DT_NEEDED 含绝对路径 /usr/lib/libmujs.so，改为普通名（长度不变，原地覆盖）
python3 - "$SYSROOT/usr/lib/libmpv.so.2" <<'PY'
import os
import sys
p = os.path.realpath(sys.argv[1])
b = open(p, "rb").read()
old, new = b"/usr/lib/libmujs.so\x00", b"libmujs.so"
i = b.find(old)
if i >= 0:
    b = b[:i] + new + b"\x00" * (len(old) - len(new)) + b[i + len(old):]
    open(p, "wb").write(b)
    print("patched", p)
PY

echo "sysroot: $SYSROOT"
