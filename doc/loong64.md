# LoongArch64 构建

在 x64 主机交叉编译 AppFlowy 桌面版（GTK）。

## 依赖

- `loongarch64-linux-gnu-` 交叉工具链（gcc/g++/ar/strip）
- Rust：rustup + `loongarch64-unknown-linux-gnu` target
- `cmake` `ninja` `bsdtar` `unzip` `curl` `git` `python3`

## 构建

```sh
LOONG64_ROOT=$HOME/loong64-build bash tools/loong64/build.sh
```

产物：`$LOONG64_ROOT/dist/AppFlowy-linux-loong64-<版本>.tar.gz`，用 `run.sh` 启动。

## 脚本

| 脚本 | 作用 |
| --- | --- |
| `fetch.sh` | 下载 Flutter loong64 SDK、Dart x64 SDK、交叉 gen_snapshot、宿主引擎工具 |
| `setup-flutter.sh` | 替换 Dart SDK，重建 flutter_tools，恢复 fork 的 patched sdk |
| `make-toolchain.sh` | 生成 sysroot 感知的编译器包装 |
| `make-sysroot.sh` | 拉取 loong64 系统库、补齐 glibc、源码编译 SDL2 |
| `patch-deps.sh` | 拉取编辑器依赖并应用兼容补丁 |
| `build-rust.sh` | 交叉编译 dart-ffi，生成 Dart protobuf/dart_event |
| `build-app.sh` | 修补 pub 缓存、构建 Flutter 应用 |
| `package.sh` | strip、附带 mpv/SDL2/mujs、打包 |

## 说明

- 首次构建下载约 2 GB；`LOONG64_ROOT` 可改工作目录。
- `RUST_TOOLCHAIN` 需与已安装工具链名一致（默认 `stable`）。
- 目标机需 GTK3 运行库；视频另需 mpv 其余依赖。
