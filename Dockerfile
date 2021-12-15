FROM tiredofit/alpine:3.15
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ENV RUBY_MAJOR=2.7 \
    RUBY_VERSION=2.7.5

RUN set -x && \
    apk add --no-cache -t .ruby-builddeps \
		autoconf \
		bison \
		bzip2 \
		bzip2-dev \
		ca-certificates \
		coreutils \
		dpkg-dev \
		dpkg \
		gcc \
		gdbm-dev \
		glib-dev \
		libc-dev \
		libffi-dev \
		libxml2-dev \
		libxslt-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
        patch \
		procps \
		readline-dev \
		ruby \
		tar \
		xz \
		yaml-dev \
		zlib-dev \
	&& \
	\
	mkdir -p /usr/src/ruby && \
	curl -sSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION:0:3}/ruby-${RUBY_VERSION}.tar.xz | tar xvfJ - --strip 1 -C /usr/src/ruby && \
	cd /usr/src/ruby && \
	\
# https://github.com/docker-library/ruby/issues/196
# https://bugs.ruby-lang.org/issues/14387#note-13 (patch source)
# https://bugs.ruby-lang.org/issues/14387#note-16 ("Therefore ncopa's patch looks good for me in general." -- only breaks glibc which doesn't matter here)
	wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch'; \
	echo '3ab628a51d92fdf0d2b5835e93564857aea73e0c1de00313864a94a6255cb645 *thread-stack-fix.patch' | sha256sum --check --strict; \
	patch -p1 -i thread-stack-fix.patch; \
	rm thread-stack-fix.patch; \
	\
# https://bugs.ruby-lang.org/issues/17723 (building with autoconf 2.70+ fails)
# https://github.com/ruby/ruby/pull/3773
	wget -O 'autoconf-2.70.patch' 'https://github.com/ruby/ruby/commit/fcc88da5eb162043adcba552646677d2ab5adf55.patch'; \
	patch -p1 -i autoconf-2.70.patch; \
	rm autoconf-2.70.patch; \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new; \
	mv file.c.new file.c && \
	\
	autoconf && \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
# the configure script does not detect isnan/isinf as macros
	export ac_cv_func_isnan=yes ac_cv_func_isinf=yes && \
	./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared \
	&& \
	make -j "$(nproc)" && \
	make install && \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" && \
	apk add -t .ruby-rundeps \
		$runDeps \
		bzip2 \
		libffi-dev \
		yaml-dev \
		zlib-dev \
	&& \
	apk del --no-network .ruby-builddeps && \
	\
	cd / && \
	rm -r /usr/src/ruby && \
# verify we have no "ruby" packages installed
	! apk --no-network list --installed \
		| grep -v '^[.]ruby-rundeps' \
		| grep -i ruby \
	&& \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ] && \
        \
# rough smoke test
	ruby --version && \
	gem --version && \
	bundle --version

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"
