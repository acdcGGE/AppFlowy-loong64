#!/usr/bin/env python3
"""从 loong64 Arch 仓库解析依赖并解包到交叉编译 sysroot。"""
import os
import re
import subprocess
import sys
import tarfile
import urllib.request

ROOT = os.environ.get("LOONG64_ROOT", os.path.expanduser("~/loong64-build"))
PACROOT = os.path.join(ROOT, "pacroot")
SYSROOT = os.path.join(ROOT, "sysroot")
MIRROR = os.environ.get("LOONG64_MIRROR", "https://mirrors.nju.edu.cn/loongarch/archlinux")
REPOS = ["core", "extra"]
# 交叉工具链已提供 glibc 等，避免重复引入
SKIP = {"glibc", "gcc-libs", "libgcc", "filesystem", "bash", "coreutils",
        "iana-etc", "tzdata"}
ROOTS = [
    "alsa-lib", "curl", "fontconfig", "freetype2", "expat", "glib2", "libxcb",
    "libx11", "libxkbcommon", "libxkbcommon-x11", "sqlite", "zstd", "wayland",
    "vulkan-headers", "libgit2", "openssl", "libxcb-render-util",
    "linux-api-headers", "gtk3", "libkeybinder3", "libnotify", "libsecret",
    "libayatana-appindicator", "mpv", "mujs",
]


def fetch(url, dest):
    if os.path.exists(dest):
        return
    print(f"  GET {url}")
    urllib.request.urlretrieve(url, dest + ".part")
    os.rename(dest + ".part", dest)


def parse_desc(path):
    entries = []
    with tarfile.open(path, "r:*") as tf:
        for m in tf.getmembers():
            if not m.name.endswith("/desc"):
                continue
            cur, key = {}, None
            for line in tf.extractfile(m).read().decode("utf-8", "replace").splitlines():
                if line.startswith("%") and line.endswith("%"):
                    key = line.strip("%")
                    cur[key] = []
                elif key:
                    cur[key].append(line)
            if "NAME" in cur:
                entries.append(cur)
    return entries


def main():
    os.makedirs(PACROOT, exist_ok=True)
    pkgs, provides = {}, {}
    for repo in REPOS:
        db = f"{PACROOT}/{repo}.db"
        fetch(f"{MIRROR}/{repo}/os/loong64/{repo}.db", db)
        for e in parse_desc(db):
            name = e["NAME"][0]
            pkgs.setdefault(name, {
                "name": name, "repo": repo,
                "filename": e["FILENAME"][0],
                "depends": e.get("DEPENDS", []),
            })
            for p in e.get("PROVIDES", []):
                provides.setdefault(p, name)
            provides.setdefault(name, name)

    def resolve(dep):
        dep = dep.strip()
        if dep in provides:
            return provides[dep]
        return provides.get(re.split(r"[<>=]", dep)[0])

    seen, queue, missing = set(), list(ROOTS), []
    while queue:
        name = resolve(queue.pop(0))
        if name is None:
            continue
        if name in seen or name in SKIP:
            continue
        seen.add(name)
        queue.extend(pkgs[name]["depends"])

    print(f"解析到 {len(seen)} 个包")
    os.makedirs(SYSROOT, exist_ok=True)
    for name in sorted(seen):
        pkg = pkgs[name]
        local = f"{PACROOT}/cache/{pkg['filename']}"
        fetch(f"{MIRROR}/{pkg['repo']}/os/loong64/{pkg['filename']}", local)
        subprocess.run(["bsdtar", "-xf", local, "-C", SYSROOT], check=True)
    print("sysroot 完成")
    return 0


if __name__ == "__main__":
    sys.exit(main())
