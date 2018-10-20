FROM tiredofit/alpine:3.8
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ENV RUBY_MAJOR=2.5 \
    RUBY_VERSION=2.5.3 \
    RUBY_DOWNLOAD_SHA256=1cc9d0359a8ea35fc6111ec830d12e60168f3b9b305a3c2578357d360fcf306f \
    RUBYGEMS_VERSION=2.7.7 \
    BUNDLER_VERSION=1.16.6

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -ex ;  \
	# skip installing gem documentation
    mkdir -p /usr/local/etc \ && \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc && \
    \
	apk add --no-cache --virtual .ruby-builddeps \
		autoconf \
		bison \
		bzip2 \
		bzip2-dev \
		ca-certificates \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		gdbm-dev \
		glib-dev \
		libc-dev \
		libffi-dev \
		libressl \
		libressl-dev \
		libxml2-dev \
		libxslt-dev \
		linux-headers \
		make \
		ncurses-dev \
		procps \
		readline-dev \
		ruby \
		tar \
		xz \
		yaml-dev \
		zlib-dev \
	&& \
	wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" && \
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - && \
	\
	mkdir -p /usr/src/ruby && \
	tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 && \
	rm ruby.tar.xz && \
	\
	cd /usr/src/ruby && \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ \
		echo '#define ENABLE_PATH_CHECK 0' ;\
		echo ;\
		cat file.c ;\
	} > file.c.new && \
	mv file.c.new file.c && \
	\
	autoconf && \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
# the configure script does not detect isnan/isinf as macros
	export ac_cv_func_isnan=yes ac_cv_func_isinf=yes && \
	./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared && \
	make -j "$(nproc)" && \
	make install && \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" && \
	apk add --virtual .ruby-rundeps $runDeps \
		bzip2 \
		ca-certificates \
		libffi-dev \
		libressl-dev \
		procps \
		yaml-dev \
		zlib-dev \
		&& \
	apk del ruby && \
	cd / && \
	rm -r /usr/src/ruby && \
	\
	gem update --system "$RUBYGEMS_VERSION" && \
	gem install bundler --version "$BUNDLER_VERSION" --force && \
	rm -r /root/.gem/

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME="/usr/local/bundle" \
    BUNDLE_PATH="/usr/local/bundle" \
	BUNDLE_BIN="/usr/local/bundle/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="/usr/local/bundle" \
    PATH="/usr/local/bundle:$PATH"

RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" && \
	chmod 777 "$GEM_HOME" "$BUNDLE_BIN" && \
    gem install rails

