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

# 配置与站点内容运行时挂载，不烤进镜像
RUN mkdir -p /srv/data /srv/run

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
