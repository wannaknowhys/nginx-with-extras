#!/usr/bin/env python3
"""把 `apk info -v` 的输出转成 manifest.json。

用法: manifest.py <components.txt> <version> <outdir>
"""
import json
import os
import sys
from datetime import datetime, timezone

PACKAGES = [
    "nginx",
    "nginx-mod-http-dav-ext",
    "nginx-mod-http-headers-more",
    "nginx-mod-http-xslt-filter",
    "fcgiwrap",
]


def main() -> int:
    src, version, outdir = sys.argv[1], sys.argv[2], sys.argv[3]
    lines = [l.strip() for l in open(src, encoding="utf-8") if l.strip()]

    packages = {}
    for name in PACKAGES:
        for line in lines:
            if line.startswith(name + "-") and line[len(name) + 1 : :1]:
                packages[name] = line[len(name) + 1 :]
                break
        else:
            packages[name] = "unknown"

    manifest = {
        "our_version": version,
        "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "image": "ghcr.io/wannaknowhys/nginx-with-extras",
        "base": "docker.io/library/alpine:latest",
        "packages": packages,
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
