#!/usr/bin/env bash
# 用可交叉的 x64 Dart SDK 替换 loong64 SDK 自带 Dart，并补齐宿主工具与交叉 gen_snapshot
set -euo pipefail
. "$(dirname "$0")/config.sh"

[ -d "$FLUTTER_SDK" ] || { echo "先运行 fetch.sh"; exit 1; }
CACHE="$FLUTTER_SDK/bin/cache"
ENG="$CACHE/artifacts/engine"

# 1. Dart SDK 换为 x64 版（flutter_tools 与 frontend_server 才能在本机运行）
rm -rf "$CACHE/dart-sdk"
tar -xf "$DL/dartsdk-linux-x64-release.tar.gz" -C "$CACHE"
[ -x "$CACHE/dart-sdk/bin/dart" ] || { echo "Dart SDK 解包失败"; exit 1; }
printf '%s' "$ENGINE_REVISION" > "$CACHE/engine-dart-sdk.stamp"

# 2. 宿主 x64 引擎工具（官方同版本引擎产物）
unzip -oq "$DL/engine-linux-x64-artifacts.zip" -d "$ENG/linux-x64"

# 3. 交叉 gen_snapshot：x64 主机生成 loong64 快照
for m in linux-loong64 linux-loong64-profile linux-loong64-release; do
  [ -d "$ENG/$m" ] && cp "$DL/gen_snapshot_linux_x64_linux_loong64" "$ENG/$m/gen_snapshot"
done

# 4. 目标架构目录补齐宿主工具（flutter 部分步骤按目标目录查找）
for m in linux-loong64 linux-loong64-profile linux-loong64-release; do
  for t in impellerc font-subset const_finder.dart.snapshot; do
    [ -d "$ENG/$m" ] && [ ! -e "$ENG/$m/$t" ] && cp "$ENG/linux-x64/$t" "$ENG/$m/$t"
  done
done

# 5. 若 patched sdk 被官方产物覆盖（缺 loong64 ABI），从 fork 的 SDK 包恢复
if ! grep -q linuxLoong64 "$ENG/common/flutter_patched_sdk_product/platform_strong.dill" 2>/dev/null; then
  tmp="$(mktemp -d)"
  tar -xf "$DL/flutter_linux_loong64_${FLUTTER_VERSION}-stable.tar.xz" -C "$tmp" \
    flutter/bin/cache/artifacts/engine/common flutter/bin/cache/pkg
  rm -rf "$ENG/common" "$CACHE/pkg"
  cp -a "$tmp/flutter/bin/cache/artifacts/engine/common" "$ENG/common"
  cp -a "$tmp/flutter/bin/cache/pkg" "$CACHE/pkg"
  rm -rf "$tmp"
fi

# 6. 用新的 Dart 重建 flutter_tools 快照
rm -f "$CACHE/flutter_tools.snapshot" "$CACHE/flutter_tools.stamp"
"$CACHE/dart-sdk/bin/dart" --snapshot="$CACHE/flutter_tools.snapshot" \
  --packages="$FLUTTER_SDK/packages/flutter_tools/.dart_tool/package_config.json" \
  "$FLUTTER_SDK/packages/flutter_tools/bin/flutter_tools.dart"
printf '%s:' "$(git -C "$FLUTTER_SDK" rev-parse HEAD)" > "$CACHE/flutter_tools.stamp"

"$FLUTTER_SDK/bin/flutter" --version
