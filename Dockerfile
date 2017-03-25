FROM debian:jessie-backports

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		liblua5.3-0 \
		libpcre3 \
	&& rm -rf /var/lib/apt/lists/*

ENV HAPROXY_MAJOR 1.7
ENV HAPROXY_VERSION 1.7.2
ENV HAPROXY_SHA256 f95b40f52a4d61feaae363c9b15bf411c16fe8f61fddb297c7afcca0072e4b2f
ENV LIBRESSL_VERSION 2.4.5
ENV LIBRESSL_SHA256 d300c4e358aee951af6dfd1684ef0c034758b47171544230f3ccf6ce24fe4347

RUN set -x \
	\
	&& apt-get update && apt-get install -y wget --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key|apt-key add - \
	&& echo "deb http://apt.llvm.org/jessie/ llvm-toolchain-jessie-4.0 main" >> /etc/apt/sources.list \
	&& echo "deb-src http://apt.llvm.org/jessie/ llvm-toolchain-jessie-4.0 main" >> /etc/apt/sources.list \
	\
	&& buildDeps=' \
		clang-4.0 \
		lldb-4.0 \
		lld-4.0 \
		libc6-dev \
		liblua5.3-dev \
		libpcre3-dev \
		libz-dev \
		make \
		wget \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O libressl.tar.gz "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz" \
	&& echo "$LIBRESSL_SHA256 *libressl.tar.gz" | sha256sum -c \
	&& mkdir -p /usr/src/libressl \
	&& tar -xzf libressl.tar.gz -C /usr/src/libressl --strip-components=1 \
	&& rm libressl.tar.gz \
	&& cd /usr/src/libressl \
	\
	&& CC="clang-4.0" \
	CXX="clang++-4.0" \
	AR="llvm-ar-4.0" \
	NM="llvm-nm-4.0 -B" \
	RANLIB="llvm-ranlib-4.0" \
	CFLAGS="-w -fPIE -DPIE -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-strong -fvisibility=hidden -flto -fsanitize=cfi -fuse-ld=gold" \
	LDFLAGS="-fuse-ld=gold -pie -z relro -z now -flto -v" \
	./configure --prefix=/usr/target/libressl --enable-shared=no \
	&& make \
	&& make install \
	&& cd - \
	\
	&& wget -O haproxy.tar.gz "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" \
	&& echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	&& make -C /usr/src/haproxy -j "$(nproc)" all \
			TARGET=linux2628 \
			USE_LUA=1 LUA_INC=/usr/include/lua5.3 LUA_LIB_NAME=lua5.3 \
			USE_OPENSSL=1 \
			USE_PCRE=1 PCREDIR= \
			USE_ZLIB=1 \
			SSL_INC=/usr/target/libressl/include \
			SSL_LIB=/usr/target/libressl/lib \
			CC="clang-4.0" \
			CFLAGS="-w -fPIE -DPIE -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-strong -fvisibility=hidden -flto -fsanitize=cfi -fuse-ld=gold" \
			LDFLAGS="-fuse-ld=gold -pie -z relro -z now -flto -v" \
	&& make -C /usr/src/haproxy install-bin \
			TARGET=linux2628 \
			USE_LUA=1 LUA_INC=/usr/include/lua5.3 LUA_LIB_NAME=lua5.3 \
			USE_OPENSSL=1 \
			USE_PCRE=1 PCREDIR= \
			USE_ZLIB=1 \
			SSL_INC=/usr/target/libressl/include \
			SSL_LIB=/usr/target/libressl/lib \
			CC="clang-4.0" \
			CFLAGS="-w -fPIE -DPIE -D_FORTIFY_SOURCE=2 -O2 -fstack-protector-strong -fvisibility=hidden -flto -fsanitize=cfi -fuse-ld=gold" \
			LDFLAGS="-fuse-ld=gold -pie -z relro -z now -flto -v" \
	&& mkdir -p /usr/local/etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy \
	&& rm -rf /usr/src/libressl \
	&& rm -rf /usr/target/libressl \
	&& apt-get purge -y --auto-remove $buildDeps

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
