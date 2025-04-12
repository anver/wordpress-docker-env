#!/bin/sh

# Debugging: Log the start of the script
echo "Starting install-php-extensions.sh script..."

# Debugging: Log the PHP version
php -v

# Install required PHP extensions
echo "Installing PHP extensions: pdo, pdo_mysql, opcache, mysqli, exif, zip, gd"
docker-php-ext-install pdo pdo_mysql opcache mysqli exif zip gd

# Enable additional PHP extensions
echo "Enabling PHP extensions: mysqli, exif, imagick, zip, gd"
docker-php-ext-enable mysqli exif imagick zip gd

# Debugging: Log the completion of the script
echo "Completed install-php-extensions.sh script."