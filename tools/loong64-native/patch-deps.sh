#!/usr/bin/env bash
# 拉取 appflowy-editor 并应用 Flutter 3.47 兼容补丁，写入 pubspec_overrides.yaml
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORK="${LOONG64_NATIVE_WORK:-$HOME/loong64-native}"
PATCHED="$WORK/patched"
APP="$REPO/frontend/appflowy_flutter"

mkdir -p "$PATCHED"
export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY:-1}"

if [ ! -d "$PATCHED/appflowy-editor/.git" ]; then
  git clone -q https://github.com/AppFlowy-IO/appflowy-editor.git "$PATCHED/appflowy-editor"
fi
git -C "$PATCHED/appflowy-editor" checkout -q 470c4e77c71b63f693ce0923a927afcd667d6f3b
git -C "$PATCHED/appflowy-editor" apply "$REPO/patches/appflowy-editor.patch" 2>/dev/null || true

if [ ! -d "$PATCHED/plugins/.git" ]; then
  git clone -q https://github.com/AppFlowy-IO/AppFlowy-plugins.git "$PATCHED/plugins"
fi
git -C "$PATCHED/plugins" checkout -q 4efcff720ed01dd4d0f5f88a9f1ff6f79f423caa

REL="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$PATCHED" "$APP")"
cat > "$APP/pubspec_overrides.yaml" <<EOF
dependency_overrides:
  appflowy_editor:
    path: $REL/appflowy-editor
  appflowy_editor_plugins:
    path: $REL/plugins/packages/appflowy_editor_plugins
EOF
echo "依赖补丁完成：$PATCHED"
