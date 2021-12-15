FROM tiredofit/debian:buster
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ENV RUBY_MAJOR=3.0 \
    RUBY_VERSION=3.0.3 \
    RUBYGEMS_VERSION=3.0.1 \
    BUNDLER_VERSION=1.17.3

# skip installing gem documentation
RUN set -ex && \
    mkdir -p /usr/local/etc && \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc && \
    \
	buildpackDeps=' \
   		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		procps \
		autoconf \
		automake \
		bzip2 \
		dpkg-dev \
		file \
		g++ \
		gcc \
		imagemagick \
		libbz2-dev \
		libc6-dev \
		libcurl4-openssl-dev \
		libdb-dev \
		libevent-dev \
		libffi-dev \
		libgdbm-dev \
		libglib2.0-dev \
		libgmp-dev \
		libjpeg-dev \
		libkrb5-dev \
		liblzma-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmaxminddb-dev \
		libncurses5-dev \
		libncursesw5-dev \
		libpng-dev \
		libpq-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libtool \
		libwebp-dev \
		libxml2-dev \
		libxslt-dev \
		libyaml-dev \
		make \
		patch \
		unzip \
		xz-utils \
		zlib1g-dev ' && \

	buildDeps=' \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
	' && \
    \
	apt-get update && \
	apt-get install -y --no-install-recommends \
			$buildpackDeps \
			$buildDeps \
			bzip2 \
			ca-certificates \
			libffi-dev \
			#libgdbm \
			libssl-dev \
			libyaml-dev \
			procps \
			zlib1g-dev \
			&& \
    \
	mkdir -p /usr/src/ruby && \
	curl -sSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" | tar xvJf - --strip 1 -C /usr/src/ruby && \
	cd /usr/src/ruby && \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ \
		echo '#define ENABLE_PATH_CHECK 0'&& \
		echo ; \
		cat file.c ;\
	} > file.c.new && \
	mv file.c.new file.c && \
	\
	autoconf && \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
	./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared && \
	make -j "$(nproc)" && \
	make install && \
    \
	#apt-get purge -y --auto-remove $buildDeps \
	cd / && \
	gem update --system  && \
	#gem install bundler --version "$BUNDLER_VERSION" --force && \
        gem install bundler && \
	rm -r /usr/src/ruby && \
	rm -rf /root/.gem/ && \
	rm -rf /var/lib/apt/lists/*

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH

RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" && \
    chmod 777 "$GEM_HOME" "$BUNDLE_BIN"
