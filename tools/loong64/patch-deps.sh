#!/usr/bin/env bash
# 拉取编辑器依赖并应用兼容补丁；把 pubspec 依赖重写为相对路径
set -euo pipefail
. "$(dirname "$0")/config.sh"
TPL="$(dirname "$0")/../../patches"

clone_ref() { # clone_ref <url> <dir> <ref>
  [ -d "$2/.git" ] || git clone -q "$1" "$2"
  git -C "$2" checkout -q "$3"
}

mkdir -p "$PATCHED"
clone_ref "$EDITOR_REPO" "$PATCHED/appflowy-editor" "$EDITOR_REF"
clone_ref "$PLUGINS_REPO" "$PATCHED/plugins" "$PLUGINS_REF"

git -C "$PATCHED/appflowy-editor" apply --check "$TPL/appflowy-editor.patch" 2>/dev/null \
  && git -C "$PATCHED/appflowy-editor" apply "$TPL/appflowy-editor.patch" || true

python3 - "$APP_DIR/pubspec.yaml" "$PATCHED" "$APP_DIR" <<'PY'
import os
import sys
pubspec, patched, app_dir = sys.argv[1:4]
s = open(pubspec).read()
rel = os.path.relpath(patched, app_dir)
s = s.replace("""  appflowy_editor:
    git:
      url: https://github.com/AppFlowy-IO/appflowy-editor.git
      ref: "470c4e7\"""", f"""  appflowy_editor:
    path: {rel}/appflowy-editor""")
s = s.replace("""  appflowy_editor_plugins:
    git:
      url: https://github.com/AppFlowy-IO/AppFlowy-plugins.git
      path: "packages/appflowy_editor_plugins"
      ref: "4efcff7\"""", f"""  appflowy_editor_plugins:
    path: {rel}/plugins/packages/appflowy_editor_plugins""")
open(pubspec, "w").write(s)
print("pubspec overrides ->", rel)
PY
