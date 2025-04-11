#!/bin/sh
apt-get update && apt-get install -y \
    zip \
    unzip \
    curl \
    nano \
    git \
    mariadb-client \
    iputils-ping \
    less \
    && rm -rf /var/lib/apt/lists/*