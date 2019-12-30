FROM tiredofit/alpine:3.11
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

ENV RUBY_VERSION=2.4.9 \
    RUBYGEMS_VERSION=3.0.3

RUN set -ex && \
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
        dpkg-dev \
        dpkg \
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
    \
    mkdir -p /usr/src/ruby && \
    curl -sSL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION:0:3}/ruby-${RUBY_VERSION}.tar.xz | tar xJf - -C /usr/src/ruby --strip-components=1 && \
    cd /usr/src/ruby && \
    \
# https://github.com/docker-library/ruby/issues/196
# https://bugs.ruby-lang.org/issues/14387#note-13 (patch source)
    wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch' && \
    patch -p1 -i thread-stack-fix.patch && \
    rm thread-stack-fix.patch && \
    \
    { \
        echo '#define ENABLE_PATH_CHECK 0'; \
        echo; \
        cat file.c; \
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
    rm -r /root/.gem/

ENV GEM_HOME="/usr/local/bundle" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_BIN="/usr/local/bundle/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="/usr/local/bundle" \
    PATH="/usr/local/bundle:$PATH"

RUN mkdir -p "$GEM_HOME"  && \
    chmod 777 "$GEM_HOME"
