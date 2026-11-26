# LoongArch64 原生构建

在 LoongArch64 Linux 上编译 AppFlowy 桌面版。

## 依赖

- Flutter loong64 SDK（dart-loong64，3.47.4）
- Rust（rustup）与 `protoc`
- `cmake` `ninja` `clang`/`gcc` `python3`
- 运行期：GTK3、mpv（视频）

## 构建

```sh
bash tools/loong64-native/build.sh
```

产物：`frontend/appflowy_flutter/build/linux/loong64/release/bundle`。

## 说明

- `patch-deps.sh`：拉取 appflowy-editor/plugins，打 Flutter 3.47 兼容补丁，生成 `pubspec_overrides.yaml`。
- `pub-cache.py`：修补 google_fonts、value_layout_builder、extended_text_field、cross_cache、super_native_extensions。
- Rust 侧用 HS256 `jsonwebtoken` 替代不支持 LoongArch 的 `ring`。
- 首次构建会生成 `lib/protobuf` 与 `lib/dispatch/dart_event`（已忽略提交）。
