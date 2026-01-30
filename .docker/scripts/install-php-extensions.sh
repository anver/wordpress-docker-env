#!/bin/sh

# Debugging: Log the start of the script
echo "Starting install-php-extensions.sh script..."

# Install the PHP extension installer
echo "Downloading and installing the PHP extension installer..."
curl -L -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions
chmod +x /usr/local/bin/install-php-extensions

# Install PHP extensions using the installer
echo "Installing PHP extensions..."
install-php-extensions \
  bz2 \
  pcntl \
  mbstring \
  bcmath \
  sockets \
  imagick \
  intl \
  pgsql \
  pdo_pgsql \
  opcache \
  exif \
  pdo_mysql \
  zip \
  uv \
  vips \
  gd \
  memcached \
  igbinary \
  ldap \
  xdebug \
  session

# Install pnpm
echo "Installing pnpm..."
npm install -g pnpm

# Cleanup
echo "Cleaning up..."
docker-php-source delete
rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Debugging: Log the completion of the script
echo "Completed install-php-extensions.sh script."
