#!/bin/sh

# Update and install necessary system dependencies using apk (Alpine package manager)
apk --no-cache add \
    bash \
    curl \
    git \
    zip \
    unzip \
    libpng \
    libjpeg-turbo \
    libwebp \
    libxpm \
    freetype \
    libxml2 \
    libxslt \
    libzip \
    icu-libs \
    imagemagick \
    imagemagick-libs \
    shadow \
    tzdata \
    autoconf \
    make \
    gcc \
    g++ \
    libc-dev \
    php-dev

# Clean up unnecessary build dependencies to reduce image size
apk del --no-cache autoconf make gcc g++ libc-dev php-dev

# Clean up
rm -rf /var/cache/apk/*