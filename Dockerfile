FROM docker.io/library/alpine:latest

# 不锁版本：任何 apk 更新都会在下一次 CI 构建里体现
RUN apk add --no-cache \
      nginx \
      nginx-mod-http-dav-ext \
      nginx-mod-http-headers-more \
      nginx-mod-http-xslt-filter \
      fcgiwrap \
      bash \
      curl \
      ca-certificates \
      tzdata \
      gettext

# 与宿主机 Debian 对齐：uid/gid 33 的 www-data，
# 这样 nginx 配置里 `user www-data;` 在容器内外行为一致，
# WebDAV/临时文件的属主也不会因为容器重建而变化。
RUN addgroup -g 33 -S www-data 2>/dev/null || true \
 && adduser  -S -D -H -u 33 -G www-data www-data 2>/dev/null || true \
 && getent passwd www-data

RUN mkdir -p /srv/data /srv/run

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
