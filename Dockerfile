# ==========================================
# Stage 1: Build mimalloc & static Nginx
# ==========================================
FROM docker.io/library/alpine:latest AS builder

RUN apk add --no-cache \
    build-base cmake git pkgconf \
    openssl-dev openssl-libs-static \
    pcre2-dev pcre2-static \
    zlib-dev zlib-static \
    libxml2-dev libxml2-static \
    libxslt-dev libxslt-static \
    xz-dev xz-static \
    linux-headers

WORKDIR /src

# 1. 始终拉取最新 mimalloc master 并静态编译
RUN git clone --depth 1 https://github.com/microsoft/mimalloc.git \
 && cmake -B mimalloc/build -S mimalloc \
      -DCMAKE_BUILD_TYPE=Release \
      -DMI_BUILD_STATIC=ON \
      -DMI_BUILD_SHARED=OFF \
      -DMI_BUILD_OBJECTS=OFF \
      -DMI_OVERRIDE=ON \
 && make -C mimalloc/build -j$(nproc) install \
 && cp $(find mimalloc/build -name 'libmimalloc.a') /usr/local/lib/libmimalloc.a

# 2. 始终拉取第三方模块 upstream master
RUN git clone --depth 1 https://github.com/arut/nginx-dav-ext-module.git \
 && git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git

# 3. 始终拉取 Nginx upstream master，全静态内嵌编译
RUN git clone --depth 1 https://github.com/nginx/nginx.git \
 && cd nginx \
 && export PKG_CONFIG="pkg-config --static" \
 && ./auto/configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/run/nginx.pid \
      --lock-path=/run/nginx.lock \
      --http-client-body-temp-path=/tmp/client_temp \
      --http-proxy-temp-path=/tmp/proxy_temp \
      --http-fastcgi-temp-path=/tmp/fastcgi_temp \
      --http-uwsgi-temp-path=/tmp/uwsgi_temp \
      --http-scgi-temp-path=/tmp/scgi_temp \
      --user=nobody \
      --group=nobody \
      --with-threads \
      --with-file-aio \
      --with-pcre-jit \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_v3_module \
      --with-http_realip_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_xslt_module \
      --with-http_gzip_static_module \
      --with-http_slice_module \
      --with-http_stub_status_module \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_realip_module \
      --with-stream_ssl_preread_module \
      --add-module=/src/nginx-dav-ext-module \
      --add-module=/src/headers-more-nginx-module \
      --with-cc-opt="-O2 -static $(pkg-config --cflags --static libxslt libxml-2.0)" \
      --with-ld-opt="-static -Wl,--whole-archive /usr/local/lib/libmimalloc.a -Wl,--no-whole-archive $(pkg-config --libs --static libxslt libxml-2.0)" \
 && make -j$(nproc) \
 && strip objs/nginx \
 && make install

# ==========================================
# Stage 2: 纯粹的 Distroless 静态运行时
# ==========================================
FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx/mime.types /etc/nginx/mime.types

EXPOSE 80 443/tcp 443/udp
STOPSIGNAL SIGQUIT
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
