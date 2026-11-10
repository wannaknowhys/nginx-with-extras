#!/usr/bin/env python3
"""把 `apk info -v` 的全量输出转成 manifest.json。

用法: manifest.py <all-packages.txt> <version> <outdir>
"""
import json
import os
import re
import sys
from datetime import datetime, timezone

PACKAGES = [
    "nginx",
    "nginx-mod-http-dav-ext",
    "nginx-mod-http-headers-more",
    "nginx-mod-http-xslt-filter",
    "fcgiwrap",
]


def parse(lines):
    """从 `apk info -v` 输出里提取指定包的版本。

    输出形如 `nginx-1.27.4-r0`，包名本身带连字符，所以按
    `^<name>-<数字开头的版本>` 精确匹配，避免前缀误配。
    """
    out = {}
    for name in PACKAGES:
        pattern = re.compile(r"^" + re.escape(name) + r"-(\d[^\s]*)$")
        for line in lines:
            m = pattern.match(line)
            if m:
                out[name] = m.group(1)
                break
        else:
            out[name] = "unknown"
    return out


def main() -> int:
    src, version, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
    lines = [l.strip() for l in open(src, encoding="utf-8") if l.strip()]

    manifest = {
        "our_version": version,
        "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "image": "ghcr.io/wannaknowhys/nginx-with-extras",
        "base": "docker.io/library/alpine:latest",
        "packages": parse(lines),
    }

    os.makedirs(outdir, exist_ok=True)
    blob = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
    for path in (os.path.join(outdir, "latest.json"), os.path.join(outdir, f"{version}.json")):
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(blob)
    print(blob)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
