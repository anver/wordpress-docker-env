#!/bin/sh

# Debugging: Log the creation of the Xdebug log directory
echo "Creating /var/log/xdebug directory..."

# Ensure the directory exists and has the correct permissions
mkdir -p /var/log/xdebug && chmod 777 /var/log/xdebug && chown www-data:www-data /var/log/xdebug

# Debugging: Log the completion of the script
echo "Xdebug log directory created and permissions set."