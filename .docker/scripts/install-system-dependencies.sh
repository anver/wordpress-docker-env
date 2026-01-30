#!/bin/sh

# Update packages and install dependencies
echo "Updating packages and installing dependencies..."
apk update
apk upgrade
apk add --no-cache \
    curl \
    nodejs \
    npm \
    wget \
    vim \
    subversion \
    tmux \
    tzdata \
    git \
    ncdu \
    procps \
    unzip \
    ca-certificates \
    libsodium-dev \
    brotli \
    bash \
    zip \
    libpng \
    libjpeg-turbo \
    libwebp \
    libxpm \
    freetype \
    libxml2 \
    libxslt \
    libzip \
    icu-libs \
    shadow

# Clean up
rm -rf /var/cache/apk/*
