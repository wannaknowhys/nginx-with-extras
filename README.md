# nginx-with-extras

Alpine 版 nginx，带 `dav-ext` / `headers-more` / `xslt-filter` 三个模块（相当于 Debian 的 `nginx-extras`），供家庭 NAS 的 WebDAV / AriaNg / 反代使用。

## 为什么不用官方镜像

官方 `nginx` 镜像缺这三个模块；自建 `nginx-extras` 又要编译。Alpine 的 `nginx-mod-http-*` 包把模块做成动态 `.so`，`apk add` 就能用，体积还小（~20 MB）。

## 版本策略：不锁版本

- 基础镜像 `alpine:latest`，`apk add` 不写版本号；
- 每次构建把自己产出的实际组件版本记进 `versions/latest.json`；
- 我们的版本号 = 构建日期 `YYYY.MM.DD`（同一天多次构建不会产生新版本，因为组件没变就跳过）。

`versions/latest.json` 是"我们的版本 → 每个组件版本"的映射，由 CI 自动生成，不需要人工维护：

```json
{
  "our_version": "2026.11.10",
  "built_at": "2026-11-10T05:17:00Z",
  "image": "ghcr.io/wannaknowhys/nginx-with-extras",
  "base": "docker.io/library/alpine:latest",
  "packages": {
    "nginx": "1.27.4-r0",
    "nginx-mod-http-dav-ext": "1.27.4-r0",
    "nginx-mod-http-headers-more": "1.27.4-r0",
    "nginx-mod-http-xslt-filter": "1.27.4-r0",
    "fcgiwrap": "1.1.0-r4"
  }
}
```

## 构建节奏

- 每天 05:17 UTC 由 GitHub Actions 构建一次；
- 组件版本与上一次相同 → **不推送、不产生新 tag**；
- 有变化 → 推送 `:latest` 和 `:YYYY.MM.DD`，并提交新的 manifest。

## 拉取

```bash
podman pull ghcr.io/wannaknowhys/nginx-with-extras:latest
```

公开仓库，匿名可拉；写操作（推送）用 `GITHUB_TOKEN`，已由 Actions 自动注入。

## 配置

镜像内只有 nginx 二进制与模块，**不含配置**。运行时挂载：

```
/srv/stacks/nginx        -> /etc/nginx
/srv/data/certs          -> /srv/data/certs
/srv/data/www            -> /srv/data/www
/srv/data/webdav         -> /srv/data/webdav
/srv/run                 -> /srv/run
```

## 本地验证构建

```bash
podman build -t nginx-with-extras:local .
podman run --rm nginx-with-extras:local sh -c 'nginx -V; apk info -v nginx'
```
