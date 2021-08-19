FROM tiredofit/alpine:3.14
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ENV RUBY_MAJOR=2.7 \
    RUBY_VERSION=2.7.4

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -eux && \
    apk update && \
    apk upgrade && \
    apk add -t .ruby-builddeps \
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
	curl -sSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION:0:3}/ruby-${RUBY_VERSION}.tar.xz" | tar xfJ - --strip 1 -C /usr/src/ruby && \
	cd /usr/src/ruby && \
	\
	wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch' && \
	patch -p1 -i thread-stack-fix.patch && \
	rm thread-stack-fix.patch && \
	\
	echo '#define ENABLE_PATH_CHECK 0' > file.c.new && \
	echo '' >> file.c.new && \
        cat file.c >> file.c.new && \
	mv file.c.new file.c && \
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
		ca-certificates \
		libffi-dev \
		procps \
		yaml-dev \
		zlib-dev \
         	&& \
	apk del .ruby-builddeps && \
	\
	cd / && \
	rm -r /usr/src/ruby && \
# verify we have no "ruby" packages installed
	! apk --no-network list --installed \
		| grep -v '^[.]ruby-rundeps' \
		| grep -i ruby \
	&& \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ] && \
# rough smoke test
	ruby --version && \
	gem --version && \
	bundle --version && \
    rm -rf /tmp/* && \
    rm -rf /usr/src/* && \
    rm -rf /var/cache/apk/* 

# don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH

RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

