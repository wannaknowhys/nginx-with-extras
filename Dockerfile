FROM docker.io/library/alpine:latest

# 只装运行时真正需要的东西。
# 不锁版本：任何 apk 更新都会在下一次 CI 构建里体现。
RUN apk add --no-cache \
      nginx \
      nginx-mod-http-dav-ext \
      nginx-mod-http-headers-more \
      nginx-mod-http-xslt-filter \
      ca-certificates \
      tzdata

# 与宿主 Debian 对齐：www-data = uid 33 / gid 33（/var/Keys/users 是 640 root:www-data）。
# Alpine 自带 www-data:82，直接 addgroup 会失败并沿用 82，所以先改写 gid。
RUN set -eux; \
    if getent group www-data >/dev/null; then \
        sed -i 's|^www-data:x:[0-9]*:|www-data:x:33:|' /etc/group; \
    else \
        addgroup -g 33 -S www-data; \
    fi; \
    if getent passwd www-data >/dev/null; then \
        sed -i 's|^www-data:x:[0-9]*:[0-9]*:|www-data:x:33:33:|' /etc/passwd; \
    else \
        adduser -S -D -H -u 33 -G www-data www-data; \
    fi; \
    getent passwd www-data; getent group www-data

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
