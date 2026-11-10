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

# 不再创建 www-data：镜像用 Alpine 自带的 nginx 用户，
# 认证文件/证书/数据目录都是 644 或 777，任何 uid 都读得到、写得进。
RUN getent passwd nginx; getent group nginx

EXPOSE 80 443
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
