#!/usr/bin/env bash
# 生成交叉编译器包装脚本（链接器指向 sysroot）
set -euo pipefail
. "$(dirname "$0")/config.sh"

mkdir -p "$TOOLWRAP"

cat > "$TOOLWRAP/loongarch64-cross-gcc" <<EOF
#!/bin/sh
exec ${CROSS_PREFIX}gcc --sysroot="$SYSROOT" -L"$SYSROOT/usr/lib" \\
  -Wl,-rpath-link,"$SYSROOT/usr/lib" "\$@"
EOF

cat > "$TOOLWRAP/clang" <<EOF
#!/bin/sh
exec ${CROSS_PREFIX}gcc --sysroot="$SYSROOT" -I"$SYSROOT/usr/include" \\
  -L"$SYSROOT/usr/lib" -Wl,-rpath-link,"$SYSROOT/usr/lib" "\$@" -Wno-error
EOF

cat > "$TOOLWRAP/clang++" <<EOF
#!/bin/sh
exec ${CROSS_PREFIX}g++ --sysroot="$SYSROOT" -I"$SYSROOT/usr/include" \\
  -L"$SYSROOT/usr/lib" -Wl,-rpath-link,"$SYSROOT/usr/lib" "\$@" -include cstdlib -Wno-error
EOF

chmod +x "$TOOLWRAP"/*
echo "工具链包装：$TOOLWRAP"
