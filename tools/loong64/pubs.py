#!/usr/bin/env python3
"""为 Flutter 3.47 / loong64 修补 pub 缓存中的第三方包（幂等）。"""
import glob
import os
import sys

CACHE = os.environ.get("PUB_CACHE") or os.path.expanduser("~/.pub-cache")


def pkg(name, version):
    hits = glob.glob(os.path.join(CACHE, "hosted", "*", f"{name}-{version}"))
    if not hits:
        sys.exit(f"未找到 {name}-{version}，请先 flutter pub get")
    return hits[0]


def edit(path, fn):
    s = open(path).read()
    t = fn(s)
    if t != s:
        open(path, "w").write(t)
        print("patched", path)


def google_fonts(p):
    edit(f"{p}/lib/src/google_fonts_variant.dart", lambda s: s.replace(
        "const _fontWeightToFilenameWeightParts = {",
        "final _fontWeightToFilenameWeightParts = {"))


def value_layout(p):
    def fix(s):
        s = s.replace("rebuildIfNecessary();", "runLayoutCallback();")
        if "RenderObjectWithLayoutCallbackMixin," not in s:
            for m in ("RenderObjectWithChildMixin<RenderBox>,\n",
                      "RenderObjectWithChildMixin<RenderSliver>,\n"):
                s = s.replace(m, m + "        RenderObjectWithLayoutCallbackMixin,\n")
        return s
    edit(f"{p}/lib/src/value_layout_builder.dart", fix)
    edit(f"{p}/lib/src/sliver_value_layout_builder.dart", fix)


def extended_text(p):
    def fix(s):
        if "_ExtendSelectionByPageIntent" in s:
            return s
        s = s.replace("ExtendSelectionByPageIntent", "_ExtendSelectionByPageIntent")
        stub = (
            "\n/// Flutter 3.47 移除了该 Intent，此处补一个本地定义。\n"
            "class _ExtendSelectionByPageIntent extends Intent {\n"
            "  const _ExtendSelectionByPageIntent({required this.forward});\n"
            "  final bool forward;\n}\n")
        marker = "part of "
        i = s.index("\n", s.index(marker)) + 1
        return s[:i] + stub + s[i:]
    edit(f"{p}/lib/src/official/widgets/editable_text.dart", fix)


def cross_cache(p):
    def fix(s):
        if "webHtmlElementStrategy" in s:
            return s
        anchor = "  @override\n  Future<NetworkImage> obtainKey("
        add = ("  @override\n  WebHtmlElementStrategy get webHtmlElementStrategy =>\n"
               "      WebHtmlElementStrategy.never;\n\n")
        return s.replace(anchor, add + anchor)
    edit(f"{p}/lib/src/cached_network_image.dart", fix)


def super_native(p):
    yaml = f"{p}/rust/cargokit.yaml"
    if os.path.exists(yaml) and "precompiled_binaries" in open(yaml).read():
        open(yaml, "w").write("{}\n")
        print("patched", yaml)

    def rustup(s):
        if "Pattern nonCustom" not in s:
            return s
        return s.replace(
            """    // To list all non-custom toolchains, we need to filter out lines that
    // don't start with "stable", "beta", or "nightly".
    Pattern nonCustom = RegExp(r"^(stable|beta|nightly)");
    final lines = res.stdout
        .toString()
        .split('\\n')
        .where((e) => e.isNotEmpty && e.startsWith(nonCustom))""",
            """    final lines = res.stdout
        .toString()
        .split('\\n')
        .where((e) => e.isNotEmpty)""")
    edit(f"{p}/cargokit/build_tool/lib/src/rustup.dart", rustup)

    def builder(s):
        if "CARGOKIT_TOOLCHAIN" in s:
            return s
        if "import 'dart:io';" not in s:
            s = "import 'dart:io';\n\n" + s
        return s.replace(
            "String get _toolchain => _buildOptions?.toolchain.name ?? 'stable';",
            "String get _toolchain =>\n      Platform.environment['CARGOKIT_TOOLCHAIN'] ??\n"
            "      _buildOptions?.toolchain.name ?? 'stable';")
    edit(f"{p}/cargokit/build_tool/lib/src/builder.dart", builder)


def main():
    google_fonts(pkg("google_fonts", "6.3.0"))
    value_layout(pkg("value_layout_builder", "0.4.0"))
    extended_text(pkg("extended_text_field", "16.0.2"))
    cross_cache(pkg("cross_cache", "0.0.6"))
    super_native(pkg("super_native_extensions", "0.8.24"))
    print("pub 缓存补丁完成")


if __name__ == "__main__":
    main()
