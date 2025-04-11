#!/bin/sh
set -eux

if [ "$(getent passwd www-data)" ]; then
    deluser --remove-home www-data
fi

if [ "$(getent group www-data)" ]; then
    deluser --remove-home www-data
fi

addgroup -g 1000 www-data
adduser -G www-data -g www-data -s /bin/sh -D www-data